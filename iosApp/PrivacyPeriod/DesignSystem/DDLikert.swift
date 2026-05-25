// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A 1–6 severity rating control whose selectors are colored along a
/// green-to-eggplant gradient and labeled with the level name, so the scale
/// reads at a glance.
///
/// Used for the DRSP daily ratings (1 = not at all … 6 = extreme). The selection
/// is optional so an unrated item reads as "not yet answered".
struct DDLikert: View {
    @Binding var selection: Int?
    var range: ClosedRange<Int> = 1...6
    /// Localization key prefix for the per-level anchor labels (`<prefix><n>`).
    /// Defaults to the DRSP severity anchors; pass another set (e.g. functional
    /// impairment: none → unable) where a different construct needs its own words.
    var labelKeyPrefix: String = "pmdd.level."
    /// Whether a higher number is the *better* state, which flips the gradient so
    /// the top of the scale is green and the bottom eggplant. Severity scales (the
    /// default) leave this off: low is green, high is eggplant. Wellbeing scales
    /// (mood, energy — where 5 is "Great") set it so the good end reads green.
    var highIsPositive: Bool = false
    /// Whether to show the per-level anchor word beneath each selector. Turn off
    /// where a single pinned scale key carries the meaning instead (so a long list
    /// of items isn't repeated under every row). The number and the color remain;
    /// the accessibility label still reads the full anchor either way.
    var showLabels: Bool = true
    private var values: [Int] { Array(range) }

    /// Maps a value to its position on the green→eggplant ramp. Identity for
    /// severity scales; mirrored within the range when a higher number is better.
    private func colorPosition(_ value: Int) -> Int {
        highIsPositive ? (range.lowerBound + range.upperBound - value) : value
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(values, id: \.self) { value in
                cell(value)
            }
        }
    }

    private func cell(_ value: Int) -> some View {
        let isSelected = selection == value
        let position = colorPosition(value)
        let color = Self.severityColor(position)
        return Button {
            selection = value
        } label: {
            VStack(spacing: 5) {
                Text("\(value)")
                    .font(.ddMono(14))
                    .foregroundColor(isSelected ? Self.selectedTextColor(position) : color)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isSelected ? color : color.opacity(0.16)))
                    .overlay(
                        Circle().strokeBorder(
                            color.opacity(isSelected ? 1 : 0.35),
                            lineWidth: isSelected ? 2 : 1
                        )
                    )
                if showLabels {
                    Text(levelLabel(value))
                        .font(.ddMono(9))
                        .foregroundColor(isSelected ? color : .ddFg3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(Text(levelLabel(value)))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// The severity color for a level, running green → eggplant as severity rises.
    static func severityColor(_ value: Int) -> Color {
        switch value {
        case 1: return Color(hex: 0x4FA15C) // green — not at all
        case 2: return Color(hex: 0x9CAE3A) // yellow-green — minimal
        case 3: return Color(hex: 0xE2A32F) // orange — mild
        case 4: return Color(hex: 0xDC7A39) // red-orange — moderate
        case 5: return Color(hex: 0xC4453B) // red — severe
        default: return Color(hex: 0x6E3D6B) // eggplant — extreme
        }
    }

    // Dark text reads better on the lighter fills (green through red-orange);
    // white only on the genuinely dark ones (red, eggplant). Keyed on the ramp
    // position, so it stays correct when the gradient is flipped.
    private static func selectedTextColor(_ position: Int) -> Color {
        position <= 4 ? .ddPlumDeep : .white
    }

    private func levelLabel(_ value: Int) -> String {
        NSLocalizedString("\(labelKeyPrefix)\(value)", comment: "rating level anchor label")
    }
}
