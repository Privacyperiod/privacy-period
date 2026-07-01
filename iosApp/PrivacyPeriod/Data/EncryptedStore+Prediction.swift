// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Period timing prediction accessors on the encrypted store.
///
/// Kept separate from `EncryptedStore+Clinical.swift` to keep that file within
/// the project's line-length guidelines.
extension EncryptedStore {
    /// Computes the next-period prediction from all logged cycles.
    ///
    /// Returns nil when the store is unavailable. Returns a result with
    /// `isReady = false` when fewer than three periods have been logged.
    func nextPeriodPrediction() -> CyclePredictionResult? {
        guard let repository else { return nil }
        return CyclePredictionEngine.shared.predict(history: repository.history())
    }

    /// Schedules or cancels the "period due tomorrow" notification based on the
    /// current prediction and the user's notification preferences.
    ///
    /// Called after every new cycle is saved and when prediction enrollment changes.
    /// No-op when the store is unavailable or the user is not enrolled.
    func reschedulePeriodPredictionNotification() {
        guard isEnrolled(moduleId: Self.cyclePredictionModuleId) else {
            NotificationManager.shared.cancelPeriodPrediction()
            return
        }
        guard let prediction = nextPeriodPrediction(),
              prediction.isReady,
              let predictedDateStr = prediction.predictedDate,
              let predictedDate = Self.date(fromISO: predictedDateStr) else {
            NotificationManager.shared.cancelPeriodPrediction()
            return
        }
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: "notif.period.enabled")
        // Default hour is 20 (8 PM) when the key has never been set.
        let hour = defaults.object(forKey: "notif.period.h") != nil
            ? defaults.integer(forKey: "notif.period.h") : 20
        let minute = defaults.integer(forKey: "notif.period.m")
        NotificationManager.shared.reschedulePeriodPrediction(
            PeriodPredictionNotifConfig(enabled: enabled, hour: hour, minute: minute),
            predictedDate: predictedDate
        )
    }
}
