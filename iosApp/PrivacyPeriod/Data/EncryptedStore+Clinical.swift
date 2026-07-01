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
    func dailyAggregateSeries(days: Int = 64, includePrediction: Bool = false) -> DailyAggregateSeries? {
        guard let database, let repository else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return nil }
        let drspIds = Set((1...24).map { "drsp_\($0)" })
        var byDate: [String: (sum: Double, items: Int)] = [:]
        for entry in repository.history().symptomEntries(symptomIds: drspIds) {
            var aggregate = byDate[entry.date] ?? (sum: 0, items: 0)
            aggregate.sum += entry.severity
            aggregate.items += 1
            byDate[entry.date] = aggregate
        }
        var bars: [DailyAggregate] = []
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: offset, to: windowStart) else { continue }
            if let aggregate = byDate[Self.isoDate(date)], aggregate.items > 0 {
                // Colour by the day's mean severity (1–6) on the shared ramp; height by
                // the aggregate sum.
                let mean = aggregate.sum / Double(aggregate.items)
                let level = min(6, max(1, Int(mean.rounded())))
                bars.append(DailyAggregate(date: date, score: aggregate.sum, severityLevel: level))
            }
        }
        let cycleStarts = database.cycleEntriesQueries.selectAllCycleEntries().executeAsList()
            .compactMap { Self.date(fromISO: $0.start_date) }
            .filter { $0 >= windowStart }
        // Distinct days in the window with at least one meal logged — non-clinical
        // context drawn along the chart baseline.
        let mealDays = Set(
            database.mealLogEntriesQueries.selectAllMealLogEntries().executeAsList()
                .compactMap { Self.date(fromISO: $0.meal_date) }
                .filter { $0 >= windowStart }
        ).sorted()
        let predictedDate: Date? = includePrediction
            ? nextPeriodPrediction()?.predictedDate.flatMap { Self.date(fromISO: $0) }
            : nil
        return DailyAggregateSeries(
            bars: bars,
            cycleStarts: cycleStarts,
            mealDays: mealDays,
            windowStart: windowStart,
            windowEnd: today,
            predictedPeriodStart: predictedDate
        )
    }

    /// Per-day counts of the three main meals (breakfast, lunch, dinner) over a
    /// rolling `days`-day window ending today.
    ///
    /// Only days where at least one main-meal entry exists appear in the result;
    /// callers should treat absent dates as zero main meals logged. Snacks and
    /// "other" entries are excluded — they don't carry the same regularity signal.
    func mealDaySummaries(days: Int) -> [MealDaySummary] {
        guard let database else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }
        let mainTypes: Set<String> = ["breakfast", "lunch", "dinner"]
        var countByDate: [String: Int] = [:]
        for entry in database.mealLogEntriesQueries.selectAllMealLogEntries().executeAsList() {
            guard mainTypes.contains(entry.meal_type) else { continue }
            guard let date = Self.date(fromISO: entry.meal_date), date >= windowStart else { continue }
            countByDate[entry.meal_date, default: 0] += 1
        }
        return countByDate.compactMap { key, count in
            guard let date = Self.date(fromISO: key) else { return nil }
            return MealDaySummary(date: date, mainMealCount: min(count, 3))
        }.sorted { $0.date < $1.date }
    }

    /// Per-day mood and energy summaries from the daily check-in, over a rolling
    /// `days`-day window ending today. One entry per logged day.
    func moodDaySummaries(days: Int) -> [MoodDaySummary] {
        guard let database else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }
        return database.moodEntriesQueries.selectAllMoodEntries().executeAsList()
            .compactMap { row -> MoodDaySummary? in
                guard let date = Self.date(fromISO: row.date), date >= windowStart else { return nil }
                return MoodDaySummary(
                    date: date,
                    moodScore: Int(row.mood_score),
                    energyScore: Int(row.energy_score)
                )
            }
            .sorted { $0.date < $1.date }
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

    func writeSymptom(
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
}
