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

    private func itemRow(_ item: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(itemLabel(item))
                .font(.ddSans(15))
                .foregroundColor(.ddPlumDeep)
            DDLikert(selection: binding(for: item))
        }
    }

    private func binding(for item: Int) -> Binding<Int?> {
        Binding(
            get: { scores[item] },
            set: { newValue in scores[item] = newValue }
        )
    }

    // The DRSP item labels are looked up by a dynamic key, so resolve them with
    // NSLocalizedString rather than an interpolated LocalizedStringKey (which
    // would be treated as a format string, not a key).
    private func itemLabel(_ item: Int) -> String {
        NSLocalizedString("pmdd.item.\(item)", comment: "DRSP item label")
    }
}
