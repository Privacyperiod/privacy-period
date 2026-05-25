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
    @State private var showingPmeCheckIn = false
    @State private var showingPmeSummary = false
    @State private var showingPmeEnroll = false
    @State private var pmeEnrolled = false
    // Set when the user taps the PME hint in the PMDD results; opens enrollment
    // once the results sheet has dismissed (avoids overlapping sheet presentation).
    @State private var pendingPmeEnroll = false
    @State private var summaryResult: CpassResult?
    @State private var pmeResult: PmePatternResult?

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
                // The PME screening entry points stay hidden until the feature is
                // clinically + safety signed off (see PmeFeature / instrument-licensing).
                // Within that, they appear only once the user has enrolled.
                if PmeFeature.shared.isEnabled {
                    if pmeEnrolled {
                        Button("pme.checkin.entry") { showingPmeCheckIn = true }
                            .font(.ddSans(15, .medium))
                            .foregroundColor(.ddSun)
                            .padding(.top, 4)
                        Button("pme.results.entry") {
                            pmeResult = store.pmePattern()
                            showingPmeSummary = true
                        }
                        .font(.ddSans(15, .medium))
                        .foregroundColor(.ddSun)
                    } else {
                        Button("pme.enroll.entry") { showingPmeEnroll = true }
                            .font(.ddSans(15, .medium))
                            .foregroundColor(.ddSun)
                            .padding(.top, 4)
                    }
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
        .sheet(isPresented: $showingSummary, onDismiss: {
            if pendingPmeEnroll {
                pendingPmeEnroll = false
                showingPmeEnroll = true
            }
        }, content: {
            PmddResultsView(
                result: summaryResult,
                onExplorePme: (PmeFeature.shared.isEnabled && !pmeEnrolled)
                    ? { pendingPmeEnroll = true; showingSummary = false }
                    : nil,
                onDone: { showingSummary = false }
            )
        })
        .sheet(isPresented: $showingPmeCheckIn) {
            PmeCheckInView(
                onCancel: { showingPmeCheckIn = false },
                onSave: { draft in
                    store.savePmeCheckIn(date: Date(), draft: draft)
                    showingPmeCheckIn = false
                }
            )
        }
        .sheet(isPresented: $showingPmeSummary) {
            PmeResultsView(result: pmeResult) { showingPmeSummary = false }
        }
        .sheet(isPresented: $showingPmeEnroll) {
            PmeEnrollmentView(
                onCancel: { showingPmeEnroll = false },
                onEnroll: { condition in
                    store.enrollPme(condition: condition)
                    pmeEnrolled = true
                    showingPmeEnroll = false
                }
            )
        }
        .onAppear { pmeEnrolled = store.isPmeEnrolled }
    }
}
