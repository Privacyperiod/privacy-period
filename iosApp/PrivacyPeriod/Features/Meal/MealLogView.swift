// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Logs a meal: its type, an optional time, and an optional short note of what it
/// was. Several meals can be logged in a row with "Save & add another".
///
/// This is intentionally not a diet or nutrition tool — it captures no calories,
/// portions, macros, or any "healthy/unhealthy" judgement. Its only purpose is to
/// give everyday context to mood and symptom tracking, so the framing stays
/// neutral and pressure-free.
struct MealLogView: View {
    /// Loads today's already-logged meals, so the list stays accurate as more are
    /// added without leaving the screen.
    let loadToday: () -> [MealLogEntry]
    let onCancel: () -> Void
    let onSave: (MealLogDraft) -> Void
    /// Saves the current meal without closing, so several can be logged in a row.
    var onSaveAnother: ((MealLogDraft) -> Void)?

    @State private var mealType = "breakfast"
    @State private var includeTime = false
    @State private var time = Date()
    @State private var description = ""
    @State private var todays: [MealLogEntry] = []

    private let mealTypes = ["breakfast", "lunch", "dinner", "snack", "other"]

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "meal.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.save") { onSave(draft()) }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("meal.intro")
                        .font(.ddSans(14))
                        .foregroundColor(.ddFg2)
                        .fixedSize(horizontal: false, vertical: true)
                    sectionHeader("meal.type")
                    VStack(spacing: 10) {
                        ForEach(mealTypes, id: \.self) { typeRow($0) }
                    }
                    timeSection
                    descriptionSection
                    if onSaveAnother != nil {
                        addAnotherButton
                    }
                    todaysList
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .onAppear { todays = loadToday() }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $includeTime) {
                Text("meal.time")
                    .font(.ddSans(13, .semibold))
                    .foregroundColor(.ddFg3)
                    .textCase(.uppercase)
            }
            .tint(.ddSun)
            if includeTime {
                DatePicker("meal.time", selection: $time, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("meal.description")
            TextField("meal.description.placeholder", text: $description, axis: .vertical)
                .font(.ddSans(15))
                .foregroundColor(.ddPlumDeep)
                .lineLimit(1...3)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinen)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).stroke(Color.ddSand, lineWidth: 1)
                )
        }
    }

    @ViewBuilder private var todaysList: some View {
        if !todays.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("meal.today")
                ForEach(todays) { meal in
                    HStack(spacing: 8) {
                        Text(NSLocalizedString("meal.type.\(meal.mealType)", comment: "meal type"))
                            .font(.ddSans(15, .medium))
                            .foregroundColor(.ddPlumDeep)
                        if let time = meal.time {
                            Text(verbatim: time).font(.ddMono(12)).foregroundColor(.ddFg2)
                        }
                        Spacer(minLength: 0)
                        if let what = meal.description, !what.isEmpty {
                            Text(verbatim: what)
                                .font(.ddSans(13))
                                .foregroundColor(.ddFg2)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func typeRow(_ value: String) -> some View {
        let isSelected = mealType == value
        return Button {
            mealType = value
        } label: {
            HStack {
                Text(NSLocalizedString("meal.type.\(value)", comment: "meal type"))
                    .font(.ddSans(16, isSelected ? .semibold : .regular))
                    .foregroundColor(.ddPlumDeep)
                Spacer()
                if isSelected {
                    DDIcon(name: "check", size: 18).foregroundColor(.ddSunDeep)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .fill(isSelected ? Color.ddSun.opacity(0.14) : Color.ddLinen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.ddSunDeep : Color.ddSand, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var addAnotherButton: some View {
        Button { logAnother() } label: {
            Text("meal.add_another")
                .font(.ddSans(16, .semibold))
                .foregroundColor(.ddSun)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                        .strokeBorder(Color.ddSun, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }

    // Saves the current meal and resets the form to log the next one, without leaving.
    private func logAnother() {
        onSaveAnother?(draft())
        todays = loadToday()
        mealType = "breakfast"
        includeTime = false
        time = Date()
        description = ""
    }

    private func draft() -> MealLogDraft {
        MealLogDraft(mealType: mealType, time: includeTime ? time : nil, description: description)
    }
}
