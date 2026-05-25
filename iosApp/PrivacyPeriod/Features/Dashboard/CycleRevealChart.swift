// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Charts
import SwiftUI

/// One logged day of Mental + Physical Daily Data: the date and its aggregate score
/// (the sum of that day's DRSP item ratings — total symptom load).
struct DailyAggregate: Identifiable {
    let date: Date
    let score: Double
    var id: Date { date }
}

/// The Mental + Physical Daily Data time series for the landing hero: a bar per logged
/// day over the recent window, plus the menses-onset dates that mark cycle boundaries.
struct DailyAggregateSeries {
    let bars: [DailyAggregate]
    let cycleStarts: [Date]
    let windowStart: Date
    let windowEnd: Date
}

/// The landing-page hero chart: a time series of the user's daily Mental + Physical
/// Data, one bar per logged day (height = that day's aggregate score), with dashed
/// markers at each period start so two cycles of collected data are visible at a
/// glance. It shows the user's own data — never a score, streak, or judgement.
struct CycleRevealChart: View {
    let series: DailyAggregateSeries

    var body: some View {
        Chart {
            ForEach(series.cycleStarts, id: \.self) { start in
                RuleMark(x: .value("Period start", start, unit: .day))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundStyle(Color.ddPlumDeep.opacity(0.25))
            }
            ForEach(series.bars) { bar in
                BarMark(
                    x: .value("Date", bar.date, unit: .day),
                    y: .value("Symptom load", bar.score),
                    width: .fixed(3)
                )
                .cornerRadius(1)
                .foregroundStyle(Color.ddSun)
            }
        }
        .chartXScale(domain: series.windowStart...series.windowEnd)
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
