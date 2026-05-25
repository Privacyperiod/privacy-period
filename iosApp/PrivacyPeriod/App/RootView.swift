// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Root of the app: onboarding on first run, then the soft mood & energy gate, then
/// the dashboard. The encrypted store is owned here and shared down so the gate and
/// the dashboard see the same data.
struct RootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var store = EncryptedStore()
    /// Whether the launch gate has been satisfied (saved or skipped) this session.
    @State private var gatePassed = false
    /// Set when onboarding completes, so the first gate appearance requires an entry.
    @State private var justOnboarded = false

    var body: some View {
        if !appState.hasCompletedOnboarding {
            OnboardingView {
                justOnboarded = true
                appState.completeOnboarding()
            }
        } else if !gatePassed && !store.hasMoodEntryToday() {
            MoodGateView(store: store, requireEntry: justOnboarded) { gatePassed = true }
        } else {
            DashboardView(store: store)
        }
    }
}
