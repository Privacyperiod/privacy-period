// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Temporary placeholder for the main dashboard, shown after onboarding.
/// Replaced by the real "Tonight" dashboard in a later milestone.
struct DashboardView: View {
    @StateObject private var store = EncryptedStore()
    @State private var showingCycleLog = false

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
    }
}
