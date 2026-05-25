// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// Temporary placeholder for the main dashboard, shown after onboarding.
/// Replaced by the real "Tonight" dashboard in a later milestone.
struct DashboardView: View {
    @StateObject private var store = EncryptedStore()
    @State private var showingCycleLog = false
    @State private var showingCheckIn = false
    @State private var showingSummary = false
    @State private var showingFlowLog = false
    @State private var showingHmbSummary = false
    @State private var summaryResult: CpassResult?
    @State private var hmbCycles: [HmbCycleScore]?

    var body: some View {
        ZStack {
            Color.ddLinen.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("dashboard.placeholder.title")
                    .font(.ddDisplay(32))
                    .foregroundColor(.ddPlumDeep)
                Text("dashboard.placeholder.body")
                    .font(.ddSans(16))
                    .foregroundColor(.ddFg2)
                DDPrimaryButton(titleKey: "dashboard.log_period") { showingCycleLog = true }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                // The PMDD screening entry points stay hidden until the feature
                // is clinically signed off (see PmddFeature / clinical-disclaimer).
                if PmddFeature.shared.isEnabled {
                    Button("pmdd.checkin.title") { showingCheckIn = true }
                        .font(.ddSans(15, .medium))
                        .foregroundColor(.ddSun)
                        .padding(.top, 4)
                    Button("pmdd.results.title") {
                        summaryResult = store.cpassResult()
                        showingSummary = true
                    }
                    .font(.ddSans(15, .medium))
                    .foregroundColor(.ddSun)
                }
                // The HMB entry points stay hidden until the feature is clinically
                // signed off (see HmbFeature / clinical-disclaimer).
                if HmbFeature.shared.isEnabled {
                    Button("hmb.flow.entry") { showingFlowLog = true }
                        .font(.ddSans(15, .medium))
                        .foregroundColor(.ddSun)
                        .padding(.top, 4)
                    Button("hmb.results.entry") {
                        hmbCycles = store.hmbCycleScores()
                        showingHmbSummary = true
                    }
                    .font(.ddSans(15, .medium))
                    .foregroundColor(.ddSun)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingCycleLog) {
            CycleLogView(
                onCancel: { showingCycleLog = false },
                onSave: { draft in
                    store.save(draft)
                    showingCycleLog = false
                }
            )
        }
        .sheet(isPresented: $showingCheckIn) {
            PmddCheckInView(
                onCancel: { showingCheckIn = false },
                onSave: { scores in
                    store.saveCheckIn(date: Date(), scores: scores)
                    showingCheckIn = false
                }
            )
        }
        .sheet(isPresented: $showingSummary) {
            PmddResultsView(result: summaryResult) { showingSummary = false }
        }
        .sheet(isPresented: $showingFlowLog) {
            FlowLogView(
                hasCycle: store.currentCycleId() != nil,
                onCancel: { showingFlowLog = false },
                onSave: { draft in
                    store.saveFlowEvent(draft)
                    showingFlowLog = false
                }
            )
        }
        .sheet(isPresented: $showingHmbSummary) {
            HmbResultsView(cycles: hmbCycles) { showingHmbSummary = false }
        }
    }
}
