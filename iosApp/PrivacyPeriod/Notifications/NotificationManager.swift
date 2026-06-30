// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import UserNotifications

/// Configuration for the meal-log reminder notifications.
///
/// Passed to `NotificationManager.rescheduleMeal(_:)` each time preferences change.
struct MealNotifConfig {
    /// Whether to fire one reminder per day or three separate ones.
    enum Frequency: String {
        /// One reminder at a user-chosen time.
        case once
        /// Three reminders: breakfast, lunch, and dinner, each at a chosen time.
        case three
    }

    /// Whether meal notifications are enabled.
    var enabled: Bool
    /// How many meal reminders to schedule per day.
    var frequency: Frequency
    /// Hour component (0–23) for the single daily reminder.
    var onceHour: Int
    /// Minute component (0–59) for the single daily reminder.
    var onceMinute: Int
    /// Hour component for the breakfast reminder.
    var breakfastHour: Int
    /// Minute component for the breakfast reminder.
    var breakfastMinute: Int
    /// Hour component for the lunch reminder.
    var lunchHour: Int
    /// Minute component for the lunch reminder.
    var lunchMinute: Int
    /// Hour component for the dinner reminder.
    var dinnerHour: Int
    /// Minute component for the dinner reminder.
    var dinnerMinute: Int
}

/// Configuration for the daily mood-and-physical check-in reminder.
///
/// Passed to `NotificationManager.rescheduleMood(_:)` each time preferences change.
struct MoodNotifConfig {
    /// Whether the mood check-in reminder is enabled.
    var enabled: Bool
    /// Hour component (0–23) for the daily reminder.
    var hour: Int
    /// Minute component (0–59) for the daily reminder.
    var minute: Int
}

/// Configuration for the period-due-tomorrow notification.
///
/// Unlike meal and mood reminders, this is a one-time notification on a specific
/// date (the evening before the predicted period start), not a repeating daily one.
/// Passed to `NotificationManager.reschedulePeriodPrediction(_:predictedDate:)`.
struct PeriodPredictionNotifConfig {
    /// Whether the period reminder is enabled.
    var enabled: Bool
    /// Hour component (0–23) for the notification. Defaults to 20 (8 PM).
    var hour: Int
    /// Minute component (0–59) for the notification.
    var minute: Int
}

/// Schedules and cancels the app's local push notifications.
///
/// All notifications are local — no data leaves the device. Each fires on a
/// repeating `UNCalendarNotificationTrigger`. The manager is stateless with
/// respect to preferences; callers supply current config on every reschedule.
final class NotificationManager {
    /// The shared instance.
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Requests notification authorisation if the status is not yet determined.
    ///
    /// Returns `true` when the app is authorised to post notifications — whether
    /// permission was already granted or was just approved. Returns `false` if the
    /// user has denied notifications or an unexpected error occurred.
    func requestPermissionIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Meal

    /// Cancels all pending meal notifications and schedules new ones per `config`.
    ///
    /// When `config.enabled` is `false` this only cancels — no new requests are added.
    func rescheduleMeal(_ config: MealNotifConfig) {
        cancelMeal()
        guard config.enabled else { return }
        switch config.frequency {
        case .once:
            schedule(
                id: "meal.once",
                title: NSLocalizedString("notif.meal.title", comment: ""),
                body: NSLocalizedString("notif.meal.body", comment: ""),
                hour: config.onceHour,
                minute: config.onceMinute
            )
        case .three:
            schedule(
                id: "meal.breakfast",
                title: NSLocalizedString("notif.meal.title", comment: ""),
                body: NSLocalizedString("notif.meal.breakfast.body", comment: ""),
                hour: config.breakfastHour,
                minute: config.breakfastMinute
            )
            schedule(
                id: "meal.lunch",
                title: NSLocalizedString("notif.meal.title", comment: ""),
                body: NSLocalizedString("notif.meal.lunch.body", comment: ""),
                hour: config.lunchHour,
                minute: config.lunchMinute
            )
            schedule(
                id: "meal.dinner",
                title: NSLocalizedString("notif.meal.title", comment: ""),
                body: NSLocalizedString("notif.meal.dinner.body", comment: ""),
                hour: config.dinnerHour,
                minute: config.dinnerMinute
            )
        }
    }

    /// Removes all pending meal-log notification requests.
    func cancelMeal() {
        center.removePendingNotificationRequests(
            withIdentifiers: ["meal.once", "meal.breakfast", "meal.lunch", "meal.dinner"]
        )
    }

    // MARK: - Mood

    /// Cancels the pending mood notification and schedules a new one per `config`.
    ///
    /// When `config.enabled` is `false` this only cancels.
    func rescheduleMood(_ config: MoodNotifConfig) {
        cancelMood()
        guard config.enabled else { return }
        schedule(
            id: "mood.daily",
            title: NSLocalizedString("notif.mood.title", comment: ""),
            body: NSLocalizedString("notif.mood.body", comment: ""),
            hour: config.hour,
            minute: config.minute
        )
    }

    /// Removes the pending mood-and-physical notification request.
    func cancelMood() {
        center.removePendingNotificationRequests(withIdentifiers: ["mood.daily"])
    }

    // MARK: - Period prediction

    /// Cancels any pending period-prediction notification and schedules a new one for
    /// the evening before `predictedDate` at the time in `config`.
    ///
    /// When `config.enabled` is false, or `predictedDate` is nil, or the fire time
    /// has already passed, this only cancels — no new request is added.
    func reschedulePeriodPrediction(_ config: PeriodPredictionNotifConfig, predictedDate: Date?) {
        cancelPeriodPrediction()
        guard config.enabled, let predictedDate else { return }
        let calendar = Calendar.current
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: predictedDate) else { return }
        var dc = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        dc.hour = config.hour
        dc.minute = config.minute
        guard let fireDate = calendar.date(from: dc), fireDate > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.period.title", comment: "")
        content.body = NSLocalizedString("notif.period.body", comment: "")
        content.sound = .default
        // repeats: false — this is a one-time notification for a specific predicted date.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let request = UNNotificationRequest(
            identifier: "period.prediction", content: content, trigger: trigger
        )
        center.add(request)
    }

    /// Removes any pending period-prediction notification request.
    func cancelPeriodPrediction() {
        center.removePendingNotificationRequests(withIdentifiers: ["period.prediction"])
    }

    // MARK: - Private

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
