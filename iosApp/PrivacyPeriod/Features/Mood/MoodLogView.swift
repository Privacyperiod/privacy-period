// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The daily mood & energy check-in — a quick 1–5 rating of each, plus an optional
/// note. One entry per day; opening it again pre-fills today's values for editing.
///
/// This is non-clinical wellbeing tracking (it never feeds clinical scoring). The
/// selectors reuse the shared green→eggplant spectrum (`DDLikert`), flipped so the
/// better state reads green — 5 ("Great"/"High") green, 1 ("Very low"/"Drained")
/// eggplant — matching every other rating spectrum in the app.
struct MoodLogView: View {
    // The leading button adapts to context: `onCancel` for the editable sheet,
    // `onSkip` for the skippable launch gate ("Not today"), or neither (no leading
    // button) when an entry is required — the first-run gate.
    let onSkip: (() -> Void)?
    let onCancel: (() -> Void)?
    let onSave: (MoodEntryDraft) -> Void

    @State private var mood: Int?
    @State private var energy: Int?
    @State private var notes: String

    private let today = Date()

    init(
        initial: MoodEntryDraft?,
        onSkip: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onSave: @escaping (MoodEntryDraft) -> Void
    ) {
        self.onSkip = onSkip
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
                leadingButton
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

    @ViewBuilder private var leadingButton: some View {
        if let onCancel {
            DDNavButton(titleKey: "common.cancel", action: onCancel)
        } else if let onSkip {
            DDNavButton(titleKey: "mood.skip", action: onSkip)
        } else {
            EmptyView()
        }
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
            // Reuse the shared spectrum selector, flipped so the better state is
            // green (highIsPositive): 5 = "Great"/"High" green, 1 = "Very low"/
            // "Drained" eggplant.
            DDLikert(
                selection: selection,
                range: 1...5,
                labelKeyPrefix: labelPrefix,
                highIsPositive: true
            )
        }
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
