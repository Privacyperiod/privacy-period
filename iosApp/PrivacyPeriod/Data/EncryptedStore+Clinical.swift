// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// The clinical-module accessors on the encrypted store: the gated screening
/// modules (PMDD, PME, HMB, perimenopause, endometriosis) read and write through
/// here. Kept separate from the core data gateway in `EncryptedStore.swift`.
extension EncryptedStore {
    /// Persists a DRSP daily check-in as same-day symptom entries on the universal
    /// clinical layer (one per rated item). No-op when the store is unavailable.
    func saveCheckIn(date: Date, scores: [Int: Int]) {
        guard let repository else { return }
        let dateString = Self.isoDate(date)
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        for (item, score) in scores {
            writeSymptom(repository, "drsp_\(item)", Double(score), dateString, now)
        }
    }

    /// Computes the PMDD screening result through the PMDD module over the
    /// universal layer, or nil when the store is unavailable.
    func cpassResult() -> CpassResult? {
        guard let repository else { return nil }
        let result = PmddModule.shared.runScoring(history: repository.history())
        return (result as? PmddScoringResult)?.result
    }

    /// Computes the PMDD-vs-PME pattern through the PME module over the universal
    /// layer, paired with its readiness, or nil when the store is unavailable.
    func pmePattern() -> PmePatternResult? {
        guard let repository else { return nil }
        let history = repository.history()
        let readiness = PmeModule.shared.checkReadiness(history: history)
        guard let scoring = PmeModule.shared.runScoring(history: history) as? PmeScoringResult else {
            return nil
        }
        return PmePatternResult(
            classification: scoring.classification,
            scoredCycles: Int(readiness.scoredCycles),
            isReady: readiness.isReady,
            condition: repository.enrollment(moduleId: Self.pmeModuleId)?.config
        )
    }

    /// Enrolls the user in the PME module with their self-reported underlying-
    /// condition family. No-op when the store is unavailable.
    func enrollPme(condition: String) {
        guard let repository else { return }
        repository.enroll(
            moduleId: Self.pmeModuleId,
            config: condition,
            now: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    /// The user's self-reported PME condition family, or nil if not enrolled.
    func pmeCondition() -> String? {
        repository?.enrollment(moduleId: Self.pmeModuleId)?.config
    }

    /// Whether the user has enrolled in the PME module.
    var isPmeEnrolled: Bool { repository?.enrollment(moduleId: Self.pmeModuleId) != nil }

    /// Persists a PME (MAC-PMSS) daily check-in: the DRSP items and the rated mood
    /// items as same-day symptom entries. A "prefer not to answer" suicidal-ideation
    /// response writes no entry. No-op when the store is unavailable.
    func savePmeCheckIn(date: Date, draft: PmeCheckInDraft) {
        guard let repository else { return }
        let dateString = Self.isoDate(date)
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        for (item, score) in draft.drsp {
            writeSymptom(repository, "drsp_\(item)", Double(score), dateString, now)
        }
        for (symptomId, score) in draft.mood {
            writeSymptom(repository, symptomId, Double(score), dateString, now)
        }
        if let siRating = draft.siRating {
            writeSymptom(repository, "macpmss_suicidal_ideation", Double(siRating), dateString, now)
        }
    }

    /// The most recent cycle's id, or nil if no period has been logged yet. Flow
    /// events attach to this cycle, since PBAC scoring is per cycle.
    func currentCycleId() -> String? {
        database?.cycleEntriesQueries.selectAllCycleEntries().executeAsList().last?.id
    }

    /// Records a flow event against the current cycle. Returns false (a no-op) when
    /// the store is unavailable or no cycle exists to attach it to.
    @discardableResult
    func saveFlowEvent(_ draft: FlowEventDraft) -> Bool {
        guard let repository, let cycleId = currentCycleId() else { return false }
        repository.saveFlowEvent(
            event: FlowEvent(
                id: UUID().uuidString,
                cycleId: cycleId,
                eventDate: Self.isoDate(Date()),
                eventTime: nil,
                flowType: draft.flowType,
                saturation: draft.saturation,
                clotSize: draft.clotSize,
                measuredMl: draft.measuredMl.map { KotlinDouble(value: $0) },
                pbacPoints: nil,
                createdAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
        return true
    }

    /// Computes the per-cycle PBAC scores through the HMB module, or nil when the
    /// store is unavailable.
    func hmbCycleScores() -> [HmbCycleScore]? {
        guard let repository else { return nil }
        let result = HmbModule.shared.runScoring(history: repository.history())
        return (result as? HmbScoringResult)?.cycles
    }

    /// Persists a completed Greene Climacteric Scale questionnaire as an instrument
    /// completion (responses as JSON; the module re-scores on read). No-op when
    /// the store is unavailable.
    func saveGreeneCompletion(_ responses: [Int: Int]) {
        guard let repository else { return }
        let json = "{" + responses.sorted { $0.key < $1.key }
            .map { "\"\($0.key)\":\($0.value)" }
            .joined(separator: ",") + "}"
        let today = Self.isoDate(Date())
        repository.saveInstrumentCompletion(
            completion: InstrumentCompletion(
                id: UUID().uuidString,
                instrumentType: "greene_climacteric",
                startDate: today,
                endDate: today,
                itemResponsesJson: json,
                computedScoresJson: nil,
                createdAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
        )
    }

    /// The user's Greene completions, each scored into its domain profile (oldest
    /// first), or nil when the store is unavailable.
    func greeneCompletions() -> [GreeneCompletionScore]? {
        guard let repository else { return nil }
        let result = GreeneModule.shared.runScoring(history: repository.history())
        return (result as? GreeneScoringResult)?.completions
    }

    /// Computes the endometriosis screening result from the questionnaire answers.
    /// A pure, stateless calculation — a screening estimate, never a diagnosis.
    func scoreEndoScreen(_ draft: EndoScreenDraft) -> EndoScreenResult {
        EndoScreenScorer.shared.score(
            inputs: EndoScreenInputs(
                familyHistory: draft.familyHistory,
                primaryInfertility: draft.primaryInfertility,
                bmiUnder22: draft.bmiUnder22,
                cyclesUnder28: draft.cyclesUnder28,
                vasDysmenorrhea: KotlinInt(value: Int32(draft.vasDysmenorrhea)),
                vasDeepDyspareunia: KotlinInt(value: Int32(draft.vasDeepDyspareunia)),
                vasGiSymptoms: KotlinInt(value: Int32(draft.vasGiSymptoms)),
                vasUrinarySymptoms: KotlinInt(value: Int32(draft.vasUrinarySymptoms))
            )
        )
    }

    private func writeSymptom(
        _ repository: ClinicalRepository,
        _ symptomId: String,
        _ severity: Double,
        _ date: String,
        _ createdAt: Int64
    ) {
        repository.saveSymptomEntry(
            entry: SymptomEntry(
                id: UUID().uuidString,
                symptomId: symptomId,
                date: date,
                severity: severity,
                cycleId: nil,
                cyclePhase: nil,
                cycleDay: nil,
                sameDayLogged: true,
                notes: nil,
                createdAt: createdAt
            )
        )
    }

    static let pmeModuleId = "pme"

    #if DEMO
    /// Replaces all user data with two cycles of sample DRSP entries (a clear luteal
    /// rise) plus the cycle starts that anchor them, so the pattern tracker can be
    /// previewed for testing and clinician review. Demo builds only — never compiled
    /// into the App Store build.
    func seedSampleData() {
        guard let repository else { return }
        deleteAllData()
        setPremenstrual(enabled: true, families: ["anxiety"])
        let calendar = Calendar.current
        let today = Date()
        // Two menses onsets, each fully surrounded by data so C-PASS can score the
        // cycle centred on it (it compares the pre-menstrual week before the onset
        // with the post-menstrual week after it).
        let onsetsDaysAgo = [42, 14]
        for daysAgo in onsetsDaysAgo {
            if let start = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                save(CycleDraft(startDate: start, endDate: nil, flow: "MEDIUM", notes: ""))
            }
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let baseSeverity = 2
        let premenstrualSeverity = 6
        // 56 days of daily DRSP ratings: a low follicular baseline that rises in the
        // seven days before each onset — a clear, cyclical premenstrual pattern.
        for daysAgo in 0...55 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let dateString = Self.isoDate(date)
            let isPremenstrual = onsetsDaysAgo.contains { onset in
                let daysBeforeOnset = daysAgo - onset
                return daysBeforeOnset >= 1 && daysBeforeOnset <= 7
            }
            let score = isPremenstrual ? premenstrualSeverity : baseSeverity
            for item in 1...24 {
                writeSymptom(repository, "drsp_\(item)", Double(score), dateString, now)
            }
        }
    }
    #endif
}
