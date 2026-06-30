// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Charts
import SwiftUI

/// One logged day of Mental + Physical Daily Data: the date, its aggregate score (the
/// sum of that day's DRSP item ratings — total symptom load, the bar height), and the
/// day's mean severity level 1–6 (the bar colour, on the shared green→eggplant ramp).
struct DailyAggregate: Identifiable {
    let date: Date
    let score: Double
    let severityLevel: Int
    var id: Date { date }
}

/// The Mental + Physical Daily Data time series for the landing hero: a bar per logged
/// day over the recent window, plus the menses-onset dates that mark cycle boundaries.
struct DailyAggregateSeries {
    let bars: [DailyAggregate]
    let cycleStarts: [Date]
    /// Days within the window on which at least one meal was logged. Drawn as subtle
    /// markers along the baseline so meals read as everyday context for the mood and
    /// symptom pattern above them — never a clinical signal of their own.
    let mealDays: [Date]
    let windowStart: Date
    let windowEnd: Date
    /// Predicted start date of the next period, or nil if there is insufficient
    /// history or the user hasn't opted into period timing prediction. When set and
    /// within the chart window, drawn as a distinct dotted rule.
    var predictedPeriodStart: Date? = nil
}

/// The landing-page hero chart: a time series of the user's daily Mental + Physical
/// Data, one bar per logged day. Bar height is the day's aggregate score; bar colour
/// is the day's mean severity on the same green→eggplant ramp as the rating selectors,
/// so intensity reads at a glance. Dashed markers sit at each period start. It shows
/// the user's own data — never a verdict, streak, or judgement.
struct CycleRevealChart: View {
    let series: DailyAggregateSeries

    var body: some View {
        Chart {
            ForEach(series.cycleStarts, id: \.self) { start in
                RuleMark(x: .value("Period start", start, unit: .day))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(Color.ddPlumDeep.opacity(0.25))
            }
            if let predicted = series.predictedPeriodStart {
                RuleMark(x: .value("Predicted period", predicted, unit: .day))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.ddSun.opacity(0.7))
            }
            ForEach(series.bars) { bar in
                BarMark(
                    x: .value("Date", bar.date, unit: .day),
                    y: .value("Symptom load", bar.score),
                    width: .fixed(3)
                )
                .cornerRadius(1)
                .foregroundStyle(DDLikert.severityColor(bar.severityLevel))
            }
            // Meals sit as small dots on the baseline — everyday context beneath the
            // mood/symptom bars, deliberately muted so they never compete with them.
            ForEach(series.mealDays, id: \.self) { day in
                PointMark(
                    x: .value("Date", day, unit: .day),
                    y: .value("Symptom load", 0)
                )
                .symbol(.circle)
                .symbolSize(10)
                .foregroundStyle(Color.ddSun.opacity(0.5))
            }
        }
        .chartXScale(domain: series.windowStart...max(series.windowEnd, series.predictedPeriodStart ?? series.windowEnd))
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 14)) { _ in
                AxisGridLine().foregroundStyle(Color.ddSand.opacity(0.4))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 120)
    }
}

/// A thin horizontal progress track (Desert Dusk styling), filled left-to-right by
/// `fraction` (0–1). Used for progress toward a clinician-ready amount of data.
struct DDProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.ddSand)
                Capsule()
                    .fill(Color.ddSun)
                    .frame(width: max(0, min(1, fraction)) * geometry.size.width)
            }
        }
        .frame(height: 8)
    }
}
