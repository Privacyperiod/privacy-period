// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Full-screen data-visualization modal: choose which data streams to overlay,
/// pick a time window, and read relative patterns across mood, symptom load,
/// and eating rhythm on one shared chart.
///
/// All streams are normalized 0–1 so they overlay cleanly without competing
/// scales. The chart never produces a verdict or clinical interpretation — it
/// shows the user's own data so they can notice patterns themselves.
struct DataVizView: View {
    @ObservedObject var store: EncryptedStore
    /// Whether the user is enrolled in PMDD or PME; gates the symptom-load stream.
    let isPremenstrualTracked: Bool
    let onClose: () -> Void

    @State private var windowDays = 30
    @State private var enabledStreams: Set<VizStream>
    @State private var data: VizDataPackage?

    init(store: EncryptedStore, isPremenstrualTracked: Bool, onClose: @escaping () -> Void) {
        self.store = store
        self.isPremenstrualTracked = isPremenstrualTracked
        self.onClose = onClose
        // Default: all enrolled streams on. Symptom load only when clinically relevant.
        let defaults: Set<VizStream> = isPremenstrualTracked
            ? [.symptomLoad, .mood, .meals]
            : [.mood, .meals]
        self._enabledStreams = State(initialValue: defaults)
    }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "viz.title") {
                DDNavButton(titleKey: "common.done", action: onClose)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    windowPicker
                    streamPicker
                    chartArea
                    legend
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .task(id: windowDays) { loadData() }
    }

    // MARK: Window picker

    private var windowPicker: some View {
        DDSegmented(
            segments: [
                DDSegment(value: 30, label: "viz.window.30"),
                DDSegment(value: 60, label: "viz.window.60"),
                DDSegment(value: 90, label: "viz.window.90")
            ],
            selection: $windowDays
        )
    }

    // MARK: Stream picker

    private var streamPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if isPremenstrualTracked {
                    streamChip(.symptomLoad, available: data?.hasSymptomData ?? false)
                }
                streamChip(.mood, available: data?.hasMoodData ?? false)
                streamChip(.meals, available: data?.hasMealData ?? false)
            }
            .padding(.horizontal, 1)
        }
    }

    @ViewBuilder
    private func streamChip(_ stream: VizStream, available: Bool) -> some View {
        let active = enabledStreams.contains(stream)
        Button {
            if active {
                enabledStreams.remove(stream)
            } else {
                enabledStreams.insert(stream)
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(active ? stream.color : Color.ddFg3.opacity(0.3))
                    .frame(width: 7, height: 7)
                Text(stream.labelKey)
                    .font(.ddSans(13, active ? .semibold : .regular))
                    .foregroundColor(active ? .ddFg2 : .ddFg3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous).fill(active ? Color.ddLinenDeep : Color.clear)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(active ? stream.color.opacity(0.5) : Color.ddSand, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(available ? 1 : 0.45)
        .disabled(!available)
        .animation(.easeInOut(duration: 0.15), value: active)
    }

    // MARK: Chart area

    @ViewBuilder
    private var chartArea: some View {
        if let pkg = data {
            if pkg.hasAnyData {
                DataVizChart(data: pkg, enabledStreams: enabledStreams)
                    .transition(.opacity)
            } else {
                emptyState
            }
        } else {
            // Loading placeholder matching the chart height.
            Color.ddLinenDeep.opacity(0.4)
                .frame(height: 160)
                .cornerRadius(DDRadius.md)
        }
    }

    private var emptyState: some View {
        Text("viz.empty")
            .font(.ddSans(14))
            .foregroundColor(.ddFg3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 20)
    }

    // MARK: Legend

    @ViewBuilder
    private var legend: some View {
        if let pkg = data, pkg.hasAnyData {
            VStack(alignment: .leading, spacing: 8) {
                if enabledStreams.contains(.meals) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.ddSun.opacity(0.15))
                            .frame(width: 14, height: 10)
                        Text("viz.legend.partial_meals")
                            .font(.ddSans(12))
                            .foregroundColor(.ddFg3)
                    }
                }
            }
        }
    }

    // MARK: Data loading

    private func loadData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let windowStart = calendar.date(byAdding: .day, value: -(windowDays - 1), to: today) ?? today
        let bars = isPremenstrualTracked
            ? (store.dailyAggregateSeries(days: windowDays)?.bars ?? [])
            : []
        data = VizDataPackage(
            windowDays: windowDays,
            windowStart: windowStart,
            windowEnd: today,
            symptomBars: bars,
            moodSeries: store.moodDaySummaries(days: windowDays),
            mealSeries: store.mealDaySummaries(days: windowDays)
        )
    }
}
