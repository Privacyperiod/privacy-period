// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The Greene Climacteric Scale questionnaire: 21 items, each rated 0 ("not at
/// all") to 3 ("extremely"), grouped by symptom domain. On save it hands the
/// responses to the parent to persist as an instrument completion.
///
/// Item labels are the official Greene Climacteric Scale wording (the scale is
/// permission-free; sourced and cross-checked against published reproductions).
/// Part of the gated Perimenopause feature (see `PeriFeature`). Not a diagnosis.
struct GreeneQuestionnaireView: View {
    let onCancel: () -> Void
    let onSave: ([Int: Int]) -> Void

    @State private var responses: [Int: Int] = [:]

    private let levelMax = 3

    private struct DomainSection: Identifiable {
        let id: String
        let header: LocalizedStringKey
        let items: [Int]
    }

    // Item numbers grouped by Greene domain. The numbers must match the scorer's
    // domain ranges (anxiety 1–6, depression 7–11, somatic 12–18, vasomotor 19–20,
    // sexual 21); order within a domain does not affect the domain score.
    private let sections: [DomainSection] = [
        DomainSection(id: "anxiety", header: "greene.domain.anxiety", items: [1, 2, 3, 4, 5, 6]),
        DomainSection(id: "depression", header: "greene.domain.depression", items: [7, 8, 9, 10, 11]),
        DomainSection(id: "somatic", header: "greene.domain.somatic", items: [12, 13, 14, 15, 16, 17, 18]),
        DomainSection(id: "vasomotor", header: "greene.domain.vasomotor", items: [19, 20]),
        DomainSection(id: "sexual", header: "greene.domain.sexual", items: [21])
    ]

    private var isComplete: Bool { (1...21).allSatisfy { responses[$0] != nil } }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "greene.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.save", isEnabled: isComplete) { onSave(responses) }
            }
            // The rating scale stays pinned below the nav so its meaning is visible
            // while scrolling the 21 items, instead of scrolling away with the intro.
            legendBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    disclaimer
                    Text("greene.intro")
                        .font(.ddSans(14))
                        .foregroundColor(.ddFg2)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader(section.header)
                            ForEach(section.items, id: \.self) { itemRow($0) }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            DDIcon(name: "shield-check", size: 18).foregroundColor(.ddPlumDeep)
            Text("greene.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    // The pinned scale key. Kept to one line — it shrinks a touch on the narrowest
    // devices (minimumScaleFactor) rather than wrapping or using a tiny base size.
    private var legendBar: some View {
        Text("greene.legend")
            .font(.ddMono(12))
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
            Text(NSLocalizedString("greene.item.\(item)", comment: "Greene item"))
                .font(.ddSans(15))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach(0...levelMax, id: \.self) { value in
                    cell(item: item, value: value)
                }
            }
        }
    }

    private func cell(item: Int, value: Int) -> some View {
        let isSelected = responses[item] == value
        let color = Self.levelColor(value)
        return Button {
            responses[item] = value
        } label: {
            Text("\(value)")
                .font(.ddMono(15))
                .foregroundColor(isSelected ? (value >= 2 ? .white : .ddPlumDeep) : color)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                        .fill(isSelected ? color : color.opacity(0.16))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                        .strokeBorder(color.opacity(isSelected ? 1 : 0.35), lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(value)"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }

    // 0 → green … 3 → red, the standard severity ramp.
    private static func levelColor(_ value: Int) -> Color {
        switch value {
        case 0: return Color(hex: 0x4FA15C)
        case 1: return Color(hex: 0x9CAE3A)
        case 2: return Color(hex: 0xE2A32F)
        default: return Color(hex: 0xC4453B)
        }
    }
}
