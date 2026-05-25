// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Charts
import SwiftUI

/// One cycle day's mean tracked symptom severity (1–6), or nil when nothing was
/// logged that day — so the reveal visibly fills in as the user logs.
struct CycleRevealPoint: Identifiable {
    let day: Int
    let severity: Double?
    var id: Int { day }
}

/// The current cycle's symptom picture for the landing-page reveal.
struct CycleReveal {
    let points: [CycleRevealPoint]
    /// Today's day of the current cycle.
    let cycleDay: Int
    /// How many days of this cycle have at least one entry (for the completeness line).
    let daysLogged: Int
}

/// The progressive reveal: the user's own cycle chart filling in. Plots the mean
/// tracked symptom severity for each logged day of the current cycle; unlogged days
/// are gaps, so the picture grows as logging continues. It shows the user's data —
/// never a score, streak, or judgement.
struct CycleRevealChart: View {
    let reveal: CycleReveal

    private var logged: [CycleRevealPoint] {
        reveal.points.filter { $0.severity != nil }
    }

    var body: some View {
        Chart(logged) { point in
            if let severity = point.severity {
                AreaMark(x: .value("Cycle day", point.day), y: .value("Symptoms", severity))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ddSun.opacity(0.35), Color.ddSun.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                LineMark(x: .value("Cycle day", point.day), y: .value("Symptoms", severity))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.ddSunDeep)
                PointMark(x: .value("Cycle day", point.day), y: .value("Symptoms", severity))
                    .foregroundStyle(Color.ddSunDeep)
                    .symbolSize(16)
            }
        }
        .chartXScale(domain: 1...max(reveal.cycleDay, 2))
        .chartYScale(domain: 1...6)
        .chartYAxis {
            AxisMarks(values: [1, 6]) { value in
                AxisValueLabel {
                    if let raw = value.as(Int.self) {
                        Text(raw == 1 ? "low" : "high").font(.ddMono(9)).foregroundColor(.ddFg3)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Color.ddSand.opacity(0.5))
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text(verbatim: "\(day)").font(.ddMono(9)).foregroundColor(.ddFg3)
                    }
                }
            }
        }
        .frame(height: 130)
    }
}
