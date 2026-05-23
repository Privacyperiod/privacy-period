// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Temporary placeholder for the main dashboard, shown after onboarding.
/// Replaced by the real "Tonight" dashboard in a later milestone.
struct DashboardView: View {
    var body: some View {
        ZStack {
            Color.ddLinen.ignoresSafeArea()
            VStack(spacing: 8) {
                Text("dashboard.placeholder.title")
                    .font(.ddDisplay(32))
                    .foregroundColor(.ddPlumDeep)
                Text("dashboard.placeholder.body")
                    .font(.ddSans(16))
                    .foregroundColor(.ddFg2)
            }
            .padding()
        }
    }
}
