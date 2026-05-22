// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The application entry point.
///
/// Privacy Period is offline-first: there is no account, no network setup, and
/// no remote configuration to perform at launch.
@main
struct PrivacyPeriodApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
