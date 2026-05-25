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

/// The app's gateway to the encrypted on-device database.
///
/// The database is opened with SQLCipher, keyed from the iOS Keychain. Opening
/// can fail when the Keychain is unavailable (notably on unsigned simulator
/// builds, which return `errSecMissingEntitlement`); in that case the store
/// degrades to unavailable rather than crashing. On a signed build the Keychain
/// is available and the store opens normally.
final class EncryptedStore: ObservableObject {
    private let database: PrivacyPeriodDatabase?
    private let repository: ClinicalRepository?

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

    /// Persists a DRSP daily check-in as same-day symptom entries on the universal
    /// clinical layer (one per rated item). No-op when the store is unavailable.
    func saveCheckIn(date: Date, scores: [Int: Int]) {
        guard let repository else { return }
        let dateString = Self.isoDate(date)
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        for (item, score) in scores {
            repository.saveSymptomEntry(
                entry: SymptomEntry(
                    id: UUID().uuidString,
                    symptomId: "drsp_\(item)",
                    date: dateString,
                    severity: Double(score),
                    cycleId: nil,
                    cyclePhase: nil,
                    cycleDay: nil,
                    sameDayLogged: true,
                    notes: nil,
                    createdAt: now
                )
            )
        }
    }

    /// Computes the PMDD screening result through the PMDD module over the
    /// universal layer, or nil when the store is unavailable.
    func cpassResult() -> CpassResult? {
        guard let repository else { return nil }
        let result = PmddModule.shared.runScoring(history: repository.history())
        return (result as? PmddScoringResult)?.result
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

    /// Computes the per-cycle PBAC scores through the HMB module over the universal
    /// layer, or nil when the store is unavailable.
    func hmbCycleScores() -> [HmbCycleScore]? {
        guard let repository else { return nil }
        let result = HmbModule.shared.runScoring(history: repository.history())
        return (result as? HmbScoringResult)?.cycles
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

    private static func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
