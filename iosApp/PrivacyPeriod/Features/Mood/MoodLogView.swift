// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The daily mood & energy check-in — a quick 1–5 rating of each, plus an optional
/// note. One entry per day; opening it again pre-fills today's values for editing.
///
/// This is non-clinical wellbeing tracking (it never feeds clinical scoring), so
/// the scale runs low → high with a single accent rather than the severity ramp.
struct MoodLogView: View {
    let onCancel: () -> Void
    let onSave: (MoodEntryDraft) -> Void

    @State private var mood: Int?
    @State private var energy: Int?
    @State private var notes: String

    private let today = Date()
    private let scale = Array(1...5)

    init(initial: MoodEntryDraft?, onCancel: @escaping () -> Void, onSave: @escaping (MoodEntryDraft) -> Void) {
        self.onCancel = onCancel
        self.onSave = onSave
        _mood = State(initialValue: initial?.mood)
        _energy = State(initialValue: initial?.energy)
        _notes = State(initialValue: initial?.notes ?? "")
    }

    private var isComplete: Bool { mood != nil && energy != nil }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "mood.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.save", isEnabled: isComplete) {
                    if let mood, let energy {
                        onSave(MoodEntryDraft(mood: mood, energy: energy, notes: notes))
                    }
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    scaleSection("mood.mood", labelPrefix: "mood.mood.", selection: $mood)
                    scaleSection("mood.energy", labelPrefix: "mood.energy.", selection: $energy)
                    notesSection
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(today, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.ddDisplay(26))
                .foregroundColor(.ddPlumDeep)
            Text("mood.intro")
                .font(.ddSans(14))
                .foregroundColor(.ddFg2)
        }
    }

    private func scaleSection(
        _ titleKey: LocalizedStringKey,
        labelPrefix: String,
        selection: Binding<Int?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(.ddSans(13, .semibold))
                .foregroundColor(.ddFg3)
                .textCase(.uppercase)
            HStack(alignment: .top, spacing: 8) {
                ForEach(scale, id: \.self) { value in
                    cell(value, labelPrefix: labelPrefix, selection: selection)
                }
            }
        }
    }

    private func cell(_ value: Int, labelPrefix: String, selection: Binding<Int?>) -> some View {
        let isSelected = selection.wrappedValue == value
        return Button {
            selection.wrappedValue = value
        } label: {
            VStack(spacing: 5) {
                Text("\(value)")
                    .font(.ddMono(14))
                    .foregroundColor(isSelected ? .ddLinen : .ddPlumDeep)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isSelected ? Color.ddSun : Color.ddSun.opacity(0.12)))
                    .overlay(Circle().strokeBorder(Color.ddSun.opacity(isSelected ? 1 : 0.3), lineWidth: 1))
                Text(NSLocalizedString("\(labelPrefix)\(value)", comment: "mood/energy level"))
                    .font(.ddMono(9))
                    .foregroundColor(isSelected ? .ddPlumDeep : .ddFg3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("mood.notes")
                .font(.ddSans(13, .semibold))
                .foregroundColor(.ddFg3)
                .textCase(.uppercase)
            TextField("mood.notes.placeholder", text: $notes, axis: .vertical)
                .font(.ddSans(15))
                .foregroundColor(.ddPlumDeep)
                .lineLimit(2...5)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinen)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).stroke(Color.ddSand, lineWidth: 1)
                )
        }
    }
}
