// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// A draft cycle entry collected from the "Log period" form, before it is
/// persisted. Decouples the form view from the storage layer.
struct CycleDraft {
    let startDate: Date
    let endDate: Date?
    /// Flow intensity token as stored: "SPOTTING", "LIGHT", "MEDIUM", "HEAVY".
    let flow: String
    let notes: String
}

/// A daily mood and energy check-in, before it is persisted (one per day).
/// `mood` and `energy` are 1–5 on the app's scale.
struct MoodEntryDraft {
    let mood: Int
    let energy: Int
    let notes: String
}

/// A factual snapshot of the current cycle for the dashboard: the latest logged
/// period's start date and how many days into the cycle today is. No prediction.
struct CycleSnapshot {
    let startDate: String
    let dayOfCycle: Int
}

/// The answers to the endometriosis screening questionnaire, before scoring.
/// VAS values are 0–10; 0 reads as "not bothered" (below every threshold).
struct EndoScreenDraft {
    let familyHistory: Bool
    let primaryInfertility: Bool
    let bmiUnder22: Bool
    let cyclesUnder28: Bool
    let vasDysmenorrhea: Int
    let vasDeepDyspareunia: Int
    let vasGiSymptoms: Int
    let vasUrinarySymptoms: Int
}

/// A draft menstrual-flow event collected from the flow-logging form, before it
/// is persisted against the current cycle.
struct FlowEventDraft {
    /// pad, tampon, cup, disc, period_underwear, clot, or flooding.
    let flowType: String
    /// Product saturation (light/moderate/heavy/soaked), or nil.
    let saturation: String?
    /// Clot size (small/large), or nil.
    let clotSize: String?
    /// Directly measured volume in millilitres (cups/discs), or nil.
    let measuredMl: Double?
}

/// The PME pattern result paired with the readiness needed to present it: the
/// PMDD-vs-PME `classification`, how many cycles were scorable, and whether that
/// meets the module's minimum.
struct PmePatternResult {
    let classification: PatternClassification
    let scoredCycles: Int
    let isReady: Bool
    /// The user's self-reported underlying-condition family id, if enrolled.
    let condition: String?

    var pattern: CyclicityPattern { classification.pattern }
}

/// The app's gateway to the encrypted on-device database.
///
/// The database is opened with SQLCipher, keyed from the iOS Keychain. Opening
/// can fail when the Keychain is unavailable (notably on unsigned simulator
/// builds, which return `errSecMissingEntitlement`); in that case the store
/// degrades to unavailable rather than crashing. On a signed build the Keychain
/// is available and the store opens normally.
final class EncryptedStore: ObservableObject {
    // Internal (not private) so the clinical-module accessors in
    // EncryptedStore+Clinical.swift can reach them; still confined to the app target.
    let database: PrivacyPeriodDatabase?
    let repository: ClinicalRepository?

    init() {
        var opened: PrivacyPeriodDatabase?
        do {
            opened = try DatabaseDriverFactoryKt.createEncryptedDatabase()
        } catch {
            // Surface, but do not crash: persistence is unavailable until the
            // encrypted database can be opened (e.g. on a signed build).
            opened = nil
            #if DEBUG
            print("EncryptedStore: encrypted database unavailable: \(error)")
            #endif
        }
        database = opened
        repository = opened.map { ClinicalRepository(database: $0) }
        ensureDeviceIdentifier()
        // Seed the clinical catalog (the DRSP items, …) so the symptom ids that
        // modules reference exist. Idempotent; degrade rather than crash if the
        // database is in an unexpected state (e.g. a stale schema on a dev device).
        do {
            try repository?.seedCatalog()
        } catch {
            #if DEBUG
            print("EncryptedStore: catalog seeding failed: \(error)")
            #endif
        }
    }

    /// Whether the encrypted store is open and able to persist data.
    var isAvailable: Bool { database != nil }

    /// Persists a cycle entry. No-op when the store is unavailable.
    func save(_ draft: CycleDraft) {
        guard let database else { return }
        let trimmedNotes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        database.cycleEntriesQueries.insertCycleEntry(
            id: UUID().uuidString,
            start_date: Self.isoDate(draft.startDate),
            end_date: draft.endDate.map(Self.isoDate),
            flow_intensity: draft.flow,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            predicted_next: nil,
            created_at: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    /// Persists today's mood & energy check-in, replacing any earlier entry for
    /// the same day. This is non-clinical wellbeing data, never part of clinical
    /// scoring. No-op when the store is unavailable.
    func saveMoodEntry(_ draft: MoodEntryDraft) {
        guard let database else { return }
        let trimmed = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        database.moodEntriesQueries.upsertMoodEntry(
            date: Self.isoDate(Date()),
            mood_score: Int64(draft.mood),
            energy_score: Int64(draft.energy),
            notes: trimmed.isEmpty ? nil : trimmed,
            created_at: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }

    /// Today's mood & energy entry, or nil if none has been logged today.
    func todayMoodEntry() -> MoodEntryDraft? {
        guard let database else { return nil }
        let row = database.moodEntriesQueries
            .selectMoodEntryForDate(date: Self.isoDate(Date()))
            .executeAsOneOrNull()
        guard let row else { return nil }
        return MoodEntryDraft(mood: Int(row.mood_score), energy: Int(row.energy_score), notes: row.notes ?? "")
    }

    /// The current cycle snapshot (latest period start + today's day-of-cycle), or
    /// nil if no period has been logged. Factual only — no prediction.
    func currentCycleSnapshot() -> CycleSnapshot? {
        guard let database else { return nil }
        guard let latest = database.cycleEntriesQueries.selectAllCycleEntries().executeAsList().last else {
            return nil
        }
        let day = Self.daysBetween(latest.start_date, Self.isoDate(Date())) + 1
        return CycleSnapshot(startDate: latest.start_date, dayOfCycle: max(day, 1))
    }

    /// A plain-text copy of the user's everyday data (cycles and mood/energy), for
    /// the user to export and keep or share. Produced only on explicit request.
    func exportData() -> String {
        guard let database else { return "No data available." }
        var lines: [String] = []
        lines.append("Privacy Period — data export")
        lines.append("Generated \(Self.exportDateString(Date()))")
        lines.append("")
        let cycles = database.cycleEntriesQueries.selectAllCycleEntries().executeAsList()
        lines.append("Cycles (\(cycles.count)):")
        for cycle in cycles {
            let end = cycle.end_date.map { " – \($0)" } ?? ""
            lines.append("  \(cycle.start_date)\(end) · flow \(cycle.flow_intensity)")
        }
        lines.append("")
        let moods = database.moodEntriesQueries.selectAllMoodEntries().executeAsList()
        lines.append("Mood & energy (\(moods.count)):")
        for mood in moods {
            lines.append("  \(mood.date): mood \(mood.mood_score)/5, energy \(mood.energy_score)/5")
        }
        return lines.joined(separator: "\n")
    }

    /// Permanently erases every table that holds user data, then resets the device
    /// identifier. The catalog/definition tables (re-seeded on launch) are kept.
    /// No-op when the store is unavailable.
    func deleteAllData() {
        guard let database else { return }
        let queries = database.maintenanceQueries
        queries.deleteAllCycleEntries()
        queries.deleteAllSymptomEntries()
        queries.deleteAllMoodEntries()
        queries.deleteAllFlowEvents()
        queries.deleteAllInstrumentCompletions()
        queries.deleteAllModuleEnrollments()
        queries.deleteAllMeasurementEntries()
        queries.deleteAllMedicationAdministrations()
        queries.deleteAllBirthControlEntries()
        queries.deleteAllEventEntries()
        queries.deleteAllAppSettings()
        ensureDeviceIdentifier()
    }

    private static func exportDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Generates and stores a random, device-local identifier on first open.
    /// It never leaves the device and is held only inside the encrypted store.
    private func ensureDeviceIdentifier() {
        guard let database else { return }
        let existing = database.appSettingsQueries
            .selectAppSetting(key: Self.deviceIdKey)
            .executeAsOneOrNull() as String?
        if existing == nil {
            database.appSettingsQueries.upsertAppSetting(
                key: Self.deviceIdKey,
                value_: UUID().uuidString
            )
        }
    }

    private static let deviceIdKey = "device_id"

    static func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Whole days from one ISO-8601 date to another (0 if either can't be parsed).
    private static func daysBetween(_ startISO: String, _ endISO: String) -> Int {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = formatter.date(from: startISO), let end = formatter.date(from: endISO) else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
