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

    /// Progress toward a clinician-ready premenstrual analysis: how many cycles have
    /// enough prospective daily data to be scored, and how many the instrument needs
    /// (C-PASS requires two). Reflects whichever premenstrual form is enrolled (the
    /// DRSP-only PMDD check-in or the PME check-in). Nil when neither is enrolled.
    func premenstrualReadiness() -> PremenstrualReadiness? {
        guard let repository else { return nil }
        let history = repository.history()
        if isEnrolled(moduleId: Self.pmeModuleId) {
            let result = PmeModule.shared.checkReadiness(history: history)
            return PremenstrualReadiness(
                scoredCycles: Int(result.scoredCycles),
                requiredCycles: Int(PmeModule.shared.minimumCyclesForScoring)
            )
        }
        if isEnrolled(moduleId: Self.pmddModuleId) {
            let result = PmddModule.shared.checkReadiness(history: history)
            return PremenstrualReadiness(
                scoredCycles: Int(result.scoredCycles),
                requiredCycles: Int(PmddModule.shared.minimumCyclesForScoring)
            )
        }
        return nil
    }

    /// The Mental + Physical Daily Data time series for the landing-page hero: one bar
    /// per logged day over the recent window, each carrying that day's *aggregate
    /// score* — the sum of the day's DRSP item ratings (total symptom load). Days with
    /// no entry produce no bar, so the picture grows as logging continues. Also returns
    /// the menses-onset dates in the window so the chart can mark cycle boundaries —
    /// making the "collect two cycles" goal visible. `days` spans roughly two cycles.
    func dailyAggregateSeries(days: Int = 64) -> DailyAggregateSeries? {
        guard let database, let repository else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return nil }
        let drspIds = Set((1...24).map { "drsp_\($0)" })
        var sumByDate: [String: Double] = [:]
        for entry in repository.history().symptomEntries(symptomIds: drspIds) {
            sumByDate[entry.date, default: 0] += entry.severity
        }
        var bars: [DailyAggregate] = []
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: offset, to: windowStart) else { continue }
            if let score = sumByDate[Self.isoDate(date)] {
                bars.append(DailyAggregate(date: date, score: score))
            }
        }
        let cycleStarts = database.cycleEntriesQueries.selectAllCycleEntries().executeAsList()
            .compactMap { Self.date(fromISO: $0.start_date) }
            .filter { $0 >= windowStart }
        return DailyAggregateSeries(
            bars: bars,
            cycleStarts: cycleStarts,
            windowStart: windowStart,
            windowEnd: today
        )
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
