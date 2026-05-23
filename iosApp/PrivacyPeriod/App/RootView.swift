// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Root of the app: shows onboarding on first run, otherwise the dashboard.
struct RootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        if appState.hasCompletedOnboarding {
            DashboardView()
        } else {
            OnboardingView { appState.completeOnboarding() }
        }
    }
}
