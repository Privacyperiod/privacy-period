// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The launch gate: the app opens onto the mood & energy check-in, so logging is the
/// first thing you do and the expectation is set that this is a place you enter data.
///
/// It is deliberately *soft* (engagement standard, autonomy + the luteal-phase test):
/// after the first run it offers a one-tap "Not today" that simply proceeds — a skip
/// is a neutral non-entry, never a failure or a broken streak. Only the very first run
/// requires an entry, to establish the habit. If today is already logged, `RootView`
/// skips the gate entirely.
struct MoodGateView: View {
    @ObservedObject var store: EncryptedStore
    /// True on the first run (just after onboarding): no skip, an entry is required.
    let requireEntry: Bool
    let onDone: () -> Void

    var body: some View {
        MoodLogView(
            initial: store.todayMoodEntry(),
            onSkip: requireEntry ? nil : onDone,
            onSave: { draft in
                store.saveMoodEntry(draft)
                onDone()
            }
        )
    }
}
