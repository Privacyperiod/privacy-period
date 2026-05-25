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

    /// The current cycle's daily symptom picture for the landing-page reveal: the mean
    /// DRSP severity logged on each cycle day so far (nil on days not yet logged, so
    /// the chart visibly fills in), plus how many of those days have any entry.
    /// Returns nil when no period has been logged yet.
    func currentCycleReveal() -> CycleReveal? {
        guard let repository, let snapshot = currentCycleSnapshot() else { return nil }
        let cycleDay = snapshot.dayOfCycle
        let drspIds = Set((1...24).map { "drsp_\($0)" })
        var sumByDay: [Int: (total: Double, count: Int)] = [:]
        for entry in repository.history().symptomEntries(symptomIds: drspIds) {
            let day = Self.daysBetween(snapshot.startDate, entry.date) + 1
            guard day >= 1, day <= cycleDay else { continue }
            var aggregate = sumByDay[day] ?? (total: 0, count: 0)
            aggregate.total += entry.severity
            aggregate.count += 1
            sumByDay[day] = aggregate
        }
        let points = (1...cycleDay).map { day -> CycleRevealPoint in
            guard let aggregate = sumByDay[day] else { return CycleRevealPoint(day: day, severity: nil) }
            return CycleRevealPoint(day: day, severity: aggregate.total / Double(aggregate.count))
        }
        return CycleReveal(points: points, cycleDay: cycleDay, daysLogged: sumByDay.count)
    }

    /// Whether the given periodic instrument (e.g. the Greene Climacteric Scale) has
    /// a completion dated in the current calendar month. Used to promote a monthly
    /// task only until it has been done for the month.
    func instrumentCompletedThisMonth(_ instrumentType: String) -> Bool {
        guard let repository else { return false }
        let monthPrefix = String(Self.isoDate(Date()).prefix(7)) // "yyyy-MM"
        return repository.history()
            .instrumentCompletions(instrumentType: instrumentType)
            .contains { $0.endDate.hasPrefix(monthPrefix) }
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
        // Enroll every condition so the seeded demo shows the full home structure.
        setPremenstrual(enabled: true, families: ["anxiety"])
        setEnrolled(moduleId: "hmb", true)
        setEnrolled(moduleId: "perimenopause", true)
        setEnrolled(moduleId: "endometriosis", true)
        let calendar = Calendar.current
        let today = Date()
        // Two menses onsets, each fully surrounded by data so C-PASS can score the
        // cycle centred on it. The most recent (24 days ago) puts "today" at cycle
        // day ~25 — late luteal — so the in-progress cycle visibly shows the rise on
        // the landing-page reveal, not just the completed cycles.
        let onsetsDaysAgo = [52, 24]
        let referenceOnset = 24
        for daysAgo in onsetsDaysAgo {
            if let start = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                save(CycleDraft(startDate: start, endDate: nil, flow: "MEDIUM", notes: ""))
            }
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let cycleLength = 28
        let lutealStart = 19
        let baseSeverity = 2
        // 63 days of daily DRSP ratings scored by cycle day: a low follicular baseline
        // that rises through the luteal phase — a clear, cyclical premenstrual pattern
        // that repeats every cycle, including the one in progress.
        for daysAgo in 0...62 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let dateString = Self.isoDate(date)
            let cycleDay = ((referenceOnset - daysAgo) % cycleLength + cycleLength) % cycleLength + 1
            let score = cycleDay >= lutealStart ? min(6, baseSeverity + (cycleDay - lutealStart + 1)) : baseSeverity
            for item in 1...24 {
                writeSymptom(repository, "drsp_\(item)", Double(score), dateString, now)
            }
        }
    }
    #endif
}
