// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The home-screen card that provides a compact preview of the user's data and
/// taps through to the full `DataVizView` modal.
///
/// Shows a 14-day mood + meal sparkline when any data exists; falls back to an
/// inviting empty-state description. The card always appears so users discover the
/// visualization before they have enough data to make it interesting.
struct DataVizCard: View {
    let moodSeries: [MoodDaySummary]
    let mealSeries: [MealDaySummary]
    let isPremenstrualTracked: Bool
    let onOpen: () -> Void

    private let previewDays = 14

    var body: some View {
        Button(action: onOpen) {
            cardContent
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                DDIcon(name: "trending-up", size: 17).foregroundColor(.ddFg2)
                Text("viz.card.title")
                    .font(.ddSans(16, .semibold))
                    .foregroundColor(.ddPlumDeep)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.ddFg3)
            }

            if hasPreviewData {
                DataVizSparkline(
                    moodSeries: moodSeries,
                    mealSeries: mealSeries,
                    windowStart: windowStart,
                    windowEnd: windowEnd
                )
            } else {
                Text("viz.card.empty")
                    .font(.ddSans(13))
                    .foregroundColor(.ddFg3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            streamDots
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddLinenDeep.opacity(0.5)))
    }

    // MARK: Stream legend dots

    private var streamDots: some View {
        HStack(spacing: 12) {
            if isPremenstrualTracked {
                legendDot(.ddPlumDeep, "viz.stream.symptoms")
            }
            legendDot(.ddSun, "viz.stream.mood")
            legendDot(.ddFg3, "viz.stream.meals")
        }
    }

    private func legendDot(_ color: Color, _ key: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color.opacity(0.8)).frame(width: 6, height: 6)
            Text(key).font(.ddSans(11)).foregroundColor(.ddFg3)
        }
    }

    // MARK: Helpers

    private var hasPreviewData: Bool { !moodSeries.isEmpty || !mealSeries.isEmpty }

    private var windowEnd: Date { Calendar.current.startOfDay(for: Date()) }

    private var windowStart: Date {
        Calendar.current.date(byAdding: .day, value: -(previewDays - 1), to: windowEnd) ?? windowEnd
    }
}
