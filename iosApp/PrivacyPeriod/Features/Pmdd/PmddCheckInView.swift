// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The DRSP daily check-in: today's ratings for the 24 DRSP items on a 1–6
/// scale, grouped into emotional, physical/other, and impact sections.
///
/// Ratings are prospective and same-day only — there is no date picker, because
/// the screening's validity depends on rating today's symptoms today. This screen
/// is part of the PMDD feature, which stays gated until clinical sign-off (see
/// `PmddFeature`); it screens, it never diagnoses.
struct PmddCheckInView: View {
    let onCancel: () -> Void
    let onSave: ([Int: Int]) -> Void

    @State private var scores: [Int: Int] = [:]
    @State private var definitionTarget: DefinitionTarget?

    /// An item the user tapped to see its definition. `symptomId` selects the
    /// (licensed) official definition; `nameKey` is the on-screen item label.
    private struct DefinitionTarget: Identifiable {
        let symptomId: String
        let nameKey: String
        var id: String { symptomId }
    }

    private let today = Date()

    // Section boundaries follow the DRSP symptom categories.
    private let emotionalItems = Array(1...8)
    private let physicalItems = Array(9...21)
    private let impactItems = Array(22...24)

    // Every DRSP category must be rated before the check-in can be saved.
    private var allItems: [Int] { emotionalItems + physicalItems + impactItems }
    private var isComplete: Bool { allItems.allSatisfy { scores[$0] != nil } }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "pmdd.checkin.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                // All categories must be answered before the check-in can be saved.
                DDNavButton(titleKey: "common.save", isEnabled: isComplete) { onSave(scores) }
            }
            // The 1–6 scale key stays pinned below the nav so its meaning is always
            // visible across the 24 items, replacing a per-selector label on each row.
            legendBar
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    disclaimer
                    header
                    section(titleKey: "pmdd.section.emotional", items: emotionalItems)
                    section(titleKey: "pmdd.section.physical", items: physicalItems)
                    section(titleKey: "pmdd.section.impact", items: impactItems)
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .sheet(item: $definitionTarget) { target in
            SymptomDefinitionSheet(
                symptomId: target.symptomId,
                nameKey: target.nameKey,
                onClose: { definitionTarget = nil }
            )
        }
    }

    /// A tappable item label that opens the definition sheet, so a clinician (or
    /// user) can read what a DRSP item means. Mirrors the PME check-in.
    private func definitionTitle(_ nameKey: String, symptomId: String) -> some View {
        Button {
            definitionTarget = DefinitionTarget(symptomId: symptomId, nameKey: nameKey)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(NSLocalizedString(nameKey, comment: "screening item name"))
                    .font(.ddSans(15))
                    .foregroundColor(.ddPlumDeep)
                    .multilineTextAlignment(.leading)
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.ddFg3)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("definition.hint"))
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            DDIcon(name: "shield-check", size: 18).foregroundColor(.ddPlumDeep)
            Text("pmdd.checkin.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.lg)
                .fill(Color.ddPlumDeep.opacity(0.08))
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("pmdd.checkin.today")
                .font(.ddSans(13, .medium))
                .foregroundColor(.ddFg3)
            Text(today, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.ddDisplay(26))
                .foregroundColor(.ddPlumDeep)
            Text("pmdd.checkin.intro")
                .font(.ddSans(14))
                .foregroundColor(.ddFg2)
                .padding(.top, 2)
        }
    }

    private func section(titleKey: LocalizedStringKey, items: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(titleKey)
                .font(.ddSans(13, .semibold))
                .foregroundColor(.ddFg3)
                .textCase(.uppercase)
            ForEach(items, id: \.self) { item in
                itemRow(item)
            }
        }
    }

    // The pinned 1–6 scale key. Kept to one line — it shrinks slightly on the
    // narrowest devices rather than wrapping or using a tiny base size.
    private var legendBar: some View {
        Text("pmdd.legend")
            .font(.ddMono(11))
            .foregroundColor(.ddFg2)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.ddLinenDeep.opacity(0.6))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.ddSand).frame(height: 1)
            }
    }

    private func itemRow(_ item: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tappable label with the info button; the severity anchors live in the
            // pinned key above rather than under every selector.
            definitionTitle("pmdd.item.\(item)", symptomId: "drsp_\(item)")
            DDLikert(selection: binding(for: item), showLabels: false)
        }
    }

    private func binding(for item: Int) -> Binding<Int?> {
        Binding(
            get: { scores[item] },
            set: { newValue in scores[item] = newValue }
        )
    }
}
