// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Lets the user configure reminder notifications for meal logging and the daily
/// mood-and-physical check-in.
///
/// Preferences are stored in `UserDefaults` via `@AppStorage` — not in the
/// encrypted health database — because notification timing is device configuration,
/// not health data. This is consistent with Principle 4, which scopes encryption
/// to clinical data at rest.
///
/// The view requests notification permission on first enable, reverts the toggle
/// if the user has denied permission, and prompts them to go to Settings.
struct NotificationsView: View {
    /// Called when the user taps "Done".
    let onClose: () -> Void

    // MARK: Meal preferences

    @AppStorage("notif.meal.enabled") private var mealEnabled = false
    @AppStorage("notif.meal.freq") private var mealFreqRaw = MealNotifConfig.Frequency.once.rawValue
    @AppStorage("notif.meal.once.h") private var mealOnceHour = 12
    @AppStorage("notif.meal.once.m") private var mealOnceMinute = 0
    @AppStorage("notif.meal.bkfst.h") private var breakfastHour = 8
    @AppStorage("notif.meal.bkfst.m") private var breakfastMinute = 0
    @AppStorage("notif.meal.lunch.h") private var lunchHour = 12
    @AppStorage("notif.meal.lunch.m") private var lunchMinute = 0
    @AppStorage("notif.meal.dinner.h") private var dinnerHour = 18
    @AppStorage("notif.meal.dinner.m") private var dinnerMinute = 0

    // MARK: Mood preferences

    @AppStorage("notif.mood.enabled") private var moodEnabled = false
    @AppStorage("notif.mood.h") private var moodHour = 20
    @AppStorage("notif.mood.m") private var moodMinute = 0

    @State private var showingPermissionAlert = false

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "notifications.title") {
                DDNavButton(titleKey: "common.done", action: onClose)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    mealSection
                    moodSection
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .alert("notifications.permission.denied.title", isPresented: $showingPermissionAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("notifications.permission.denied.body")
        }
    }

    // MARK: Sections

    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("notifications.section.meal")
            toggleRow(
                icon: "bell",
                titleKey: "notifications.meal.enabled",
                helpKey: "notifications.meal.enabled.help",
                isOn: $mealEnabled
            )
            .onChange(of: mealEnabled, perform: { enabled in
                handleToggle(
                    enabled: enabled,
                    reschedule: rescheduleMeal,
                    cancel: NotificationManager.shared.cancelMeal,
                    revert: { mealEnabled = false }
                )
            })
            if mealEnabled {
                mealControls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: mealEnabled)
    }

    @ViewBuilder
    private var mealControls: some View {
        let freqBinding = Binding<MealNotifConfig.Frequency>(
            get: { MealNotifConfig.Frequency(rawValue: mealFreqRaw) ?? .once },
            set: { mealFreqRaw = $0.rawValue; rescheduleMeal() }
        )
        VStack(spacing: 12) {
            DDSegmented(
                segments: [
                    DDSegment(value: MealNotifConfig.Frequency.once, label: "notifications.meal.freq.once"),
                    DDSegment(value: MealNotifConfig.Frequency.three, label: "notifications.meal.freq.three")
                ],
                selection: freqBinding
            )
            .animation(.easeInOut(duration: 0.15), value: mealFreqRaw)
            if freqBinding.wrappedValue == .once {
                timePickerRow(
                    label: "notifications.meal.time.once",
                    hour: $mealOnceHour,
                    minute: $mealOnceMinute,
                    onReschedule: rescheduleMeal
                )
            } else {
                timePickerRow(
                    label: "notifications.meal.time.breakfast",
                    hour: $breakfastHour,
                    minute: $breakfastMinute,
                    onReschedule: rescheduleMeal
                )
                timePickerRow(
                    label: "notifications.meal.time.lunch",
                    hour: $lunchHour,
                    minute: $lunchMinute,
                    onReschedule: rescheduleMeal
                )
                timePickerRow(
                    label: "notifications.meal.time.dinner",
                    hour: $dinnerHour,
                    minute: $dinnerMinute,
                    onReschedule: rescheduleMeal
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: mealFreqRaw)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("notifications.section.mood")
            toggleRow(
                icon: "bell",
                titleKey: "notifications.mood.enabled",
                helpKey: "notifications.mood.enabled.help",
                isOn: $moodEnabled
            )
            .onChange(of: moodEnabled, perform: { enabled in
                handleToggle(
                    enabled: enabled,
                    reschedule: rescheduleMood,
                    cancel: NotificationManager.shared.cancelMood,
                    revert: { moodEnabled = false }
                )
            })
            if moodEnabled {
                timePickerRow(
                    label: "notifications.mood.time",
                    hour: $moodHour,
                    minute: $moodMinute,
                    onReschedule: rescheduleMood
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: moodEnabled)
    }

    // MARK: Reusable rows

    /// A card row containing a label, help text, and a toggle on the trailing edge.
    @ViewBuilder
    private func toggleRow(
        icon: String,
        titleKey: LocalizedStringKey,
        helpKey: LocalizedStringKey,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            DDIcon(name: icon, size: 18).foregroundColor(.ddPlumDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey)
                    .font(.ddSans(16, .medium))
                    .foregroundColor(.ddPlumDeep)
                Text(helpKey)
                    .font(.ddSans(13))
                    .foregroundColor(.ddFg3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.ddPlumDeep)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).stroke(Color.ddSand, lineWidth: 1)
        )
    }

    /// A labelled row containing a `DatePicker` restricted to hours and minutes.
    ///
    /// Writing to `hour` or `minute` automatically calls `onReschedule` so that
    /// pending notifications update immediately.
    @ViewBuilder
    private func timePickerRow(
        label: LocalizedStringKey,
        hour: Binding<Int>,
        minute: Binding<Int>,
        onReschedule: @escaping () -> Void
    ) -> some View {
        let dateBinding = Binding<Date>(
            get: {
                let dc = DateComponents(hour: hour.wrappedValue, minute: minute.wrappedValue)
                return Calendar.current.date(from: dc) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                hour.wrappedValue = comps.hour ?? hour.wrappedValue
                minute.wrappedValue = comps.minute ?? minute.wrappedValue
                onReschedule()
            }
        )
        HStack {
            Text(label)
                .font(.ddSans(15))
                .foregroundColor(.ddFg1)
            Spacer()
            DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).stroke(Color.ddSand, lineWidth: 1)
        )
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }

    // MARK: Permission + scheduling

    /// Requests permission when a toggle turns on, schedules if granted, or reverts
    /// and shows an alert if the user has denied notifications.
    private func handleToggle(
        enabled: Bool,
        reschedule: @escaping () -> Void,
        cancel: @escaping () -> Void,
        revert: @escaping () -> Void
    ) {
        if enabled {
            Task { @MainActor in
                let granted = await NotificationManager.shared.requestPermissionIfNeeded()
                if granted {
                    reschedule()
                } else {
                    revert()
                    showingPermissionAlert = true
                }
            }
        } else {
            cancel()
        }
    }

    private func rescheduleMeal() {
        NotificationManager.shared.rescheduleMeal(MealNotifConfig(
            enabled: mealEnabled,
            frequency: MealNotifConfig.Frequency(rawValue: mealFreqRaw) ?? .once,
            onceHour: mealOnceHour,
            onceMinute: mealOnceMinute,
            breakfastHour: breakfastHour,
            breakfastMinute: breakfastMinute,
            lunchHour: lunchHour,
            lunchMinute: lunchMinute,
            dinnerHour: dinnerHour,
            dinnerMinute: dinnerMinute
        ))
    }

    private func rescheduleMood() {
        NotificationManager.shared.rescheduleMood(MoodNotifConfig(
            enabled: moodEnabled,
            hour: moodHour,
            minute: moodMinute
        ))
    }
}
