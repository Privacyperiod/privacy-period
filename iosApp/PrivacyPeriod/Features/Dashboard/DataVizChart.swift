// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Charts
import SwiftUI

/// A data stream selectable for the visualization chart.
enum VizStream: String, Hashable, CaseIterable {
    /// PMDD/PME daily aggregate symptom load (only available when enrolled).
    case symptomLoad
    /// Daily mood score from the quick check-in.
    case mood
    /// Daily count of main meals (breakfast, lunch, dinner) logged.
    case meals

    /// Localized display label.
    var labelKey: LocalizedStringKey {
        switch self {
        case .symptomLoad: return "viz.stream.symptoms"
        case .mood: return "viz.stream.mood"
        case .meals: return "viz.stream.meals"
        }
    }

    /// Chart color for this stream.
    var color: Color {
        switch self {
        case .symptomLoad: return .ddPlumDeep
        case .mood: return .ddSun
        case .meals: return .ddFg3
        }
    }
}

/// All data needed to render one configuration of the visualization chart.
///
/// Aggregated once per (window × available streams) render cycle; the chart
/// itself is a pure view over this package.
struct VizDataPackage {
    let windowDays: Int
    let windowStart: Date
    let windowEnd: Date
    /// Daily aggregate symptom bars (empty when no clinical condition is enrolled).
    let symptomBars: [DailyAggregate]
    let moodSeries: [MoodDaySummary]
    let mealSeries: [MealDaySummary]

    var hasAnyData: Bool { !symptomBars.isEmpty || !moodSeries.isEmpty || !mealSeries.isEmpty }
    var hasSymptomData: Bool { !symptomBars.isEmpty }
    var hasMoodData: Bool { !moodSeries.isEmpty }
    var hasMealData: Bool { !mealSeries.isEmpty }
}

/// The main data-visualization chart.
///
/// All streams are normalized to the 0–1 range so they overlay on a shared Y axis
/// without competing scales. The Y axis is intentionally hidden: this chart shows
/// relative patterns over time — correlations between mood, symptom load, and eating
/// rhythm — not absolute clinical measurements.
///
/// Past days where fewer than 3 main meals were logged receive a subtle background
/// tint to surface eating rhythm without shaming or pressuring (Principle 9).
struct DataVizChart: View {
    let data: VizDataPackage
    let enabledStreams: Set<VizStream>

    private var maxSymptom: Double {
        max(1, data.symptomBars.map(\.score).max() ?? 1)
    }

    var body: some View {
        Chart {
            // Missed-meal background tint (drawn first so all other marks sit above).
            if enabledStreams.contains(.meals) {
                ForEach(missedMealDays, id: \.self) { day in
                    RectangleMark(
                        x: .value("Date", day, unit: .day),
                        yStart: .value("Floor", 0.0),
                        yEnd: .value("Band", 1.0)
                    )
                    .foregroundStyle(Color.ddSun.opacity(0.07))
                }
            }
            // Meal bars (main-meal count, normalized 0-3 → 0-1).
            if enabledStreams.contains(.meals) {
                ForEach(data.mealSeries) { summary in
                    BarMark(
                        x: .value("Date", summary.date, unit: .day),
                        y: .value("Meals", Double(summary.mainMealCount) / 3.0),
                        width: .fixed(4)
                    )
                    .cornerRadius(1)
                    .foregroundStyle(Color.ddFg3.opacity(0.4))
                }
            }
            // Symptom load line (normalized by the window maximum). Drawn as a
            // line rather than bars so it doesn't stack with the meal bars.
            if enabledStreams.contains(.symptomLoad) {
                ForEach(data.symptomBars) { bar in
                    LineMark(
                        x: .value("Date", bar.date, unit: .day),
                        y: .value("Symptom load", bar.score / maxSymptom)
                    )
                    .foregroundStyle(Color.ddPlumDeep)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    PointMark(
                        x: .value("Date", bar.date, unit: .day),
                        y: .value("Symptom load", bar.score / maxSymptom)
                    )
                    .symbolSize(18)
                    .foregroundStyle(Color.ddPlumDeep)
                }
            }
            // Mood line (1–5 scale → 0–1).
            if enabledStreams.contains(.mood) {
                ForEach(data.moodSeries) { entry in
                    let normalized = Double(entry.moodScore - 1) / 4.0
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Mood", normalized)
                    )
                    .foregroundStyle(Color.ddSun)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    PointMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Mood", normalized)
                    )
                    .symbolSize(22)
                    .foregroundStyle(Color.ddSun)
                }
            }
        }
        .chartXScale(domain: data.windowStart...data.windowEnd)
        .chartYScale(domain: 0...1)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: axisStride)) { _ in
                AxisGridLine().foregroundStyle(Color.ddSand.opacity(0.4))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color.ddFg3)
            }
        }
        .frame(height: 160)
    }

    // MARK: Helpers

    private var axisStride: Int {
        switch data.windowDays {
        case ...30: return 7
        case ...60: return 14
        default: return 21
        }
    }

    /// Past days (after the user's first meal log entry) where fewer than 3 main
    /// meals were logged. Today is excluded — the day is not yet over.
    private var missedMealDays: [Date] {
        guard let firstDay = data.mealSeries.min(by: { $0.date < $1.date })?.date else { return [] }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let loggedCounts = Dictionary(
            uniqueKeysWithValues: data.mealSeries.map { ($0.date, $0.mainMealCount) }
        )
        var missed: [Date] = []
        for offset in 0..<data.windowDays {
            let daysBack = data.windowDays - 1 - offset
            guard let day = calendar.date(byAdding: .day, value: -daysBack, to: todayStart) else { continue }
            guard day < todayStart, day >= firstDay else { continue }
            if (loggedCounts[day] ?? 0) < 3 {
                missed.append(day)
            }
        }
        return missed
    }
}

/// A compact sparkline for the home-screen card: mood line over meal bars,
/// no axes, no labels — just the pattern shape.
struct DataVizSparkline: View {
    let moodSeries: [MoodDaySummary]
    let mealSeries: [MealDaySummary]
    let windowStart: Date
    let windowEnd: Date

    var body: some View {
        Chart {
            ForEach(mealSeries) { summary in
                BarMark(
                    x: .value("Date", summary.date, unit: .day),
                    y: .value("Meals", Double(summary.mainMealCount) / 3.0),
                    width: .fixed(3)
                )
                .cornerRadius(1)
                .foregroundStyle(Color.ddFg3.opacity(0.25))
            }
            ForEach(moodSeries) { entry in
                LineMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Mood", Double(entry.moodScore - 1) / 4.0)
                )
                .foregroundStyle(Color.ddSun.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXScale(domain: windowStart...windowEnd)
        .chartYScale(domain: 0...1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 48)
    }
}
