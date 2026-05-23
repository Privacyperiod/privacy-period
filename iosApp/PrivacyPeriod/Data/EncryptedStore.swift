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

/// The app's gateway to the encrypted on-device database.
///
/// The database is opened with SQLCipher, keyed from the iOS Keychain. Opening
/// can fail when the Keychain is unavailable (notably on unsigned simulator
/// builds, which return `errSecMissingEntitlement`); in that case the store
/// degrades to unavailable rather than crashing. On a signed build the Keychain
/// is available and the store opens normally.
final class EncryptedStore: ObservableObject {
    private let database: PrivacyPeriodDatabase?

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
        ensureDeviceIdentifier()
    }

    /// Whether the encrypted store is open and able to persist data.
    var isAvailable: Bool { database != nil }

    /// Persists a cycle entry. No-op when the store is unavailable.
    func save(_ draft: CycleDraft) {
        guard let database else { return }
        let trimmedNotes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        database.cycleEntriesQueries.insertCycleEntry(
            start_date: Self.isoDate(draft.startDate),
            end_date: draft.endDate.map(Self.isoDate),
            flow_intensity: draft.flow,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            created_at: Int64(Date().timeIntervalSince1970 * 1000)
        )
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
