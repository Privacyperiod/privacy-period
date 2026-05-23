// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import SwiftUI

/// App-wide UI state.
///
/// Whether onboarding has been completed is a non-sensitive UI flag, kept in
/// `UserDefaults`. Encrypted on-device storage — the SQLCipher database and the
/// local device identifier — is introduced with the first data-logging feature,
/// where Keychain availability can be handled gracefully rather than at launch.
final class AppState: ObservableObject {
    @Published private(set) var hasCompletedOnboarding: Bool

    private let defaults: UserDefaults
    private static let onboardingKey = "onboarding_complete"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Self.onboardingKey)
    }

    /// Records that onboarding is complete so it isn't shown again.
    func completeOnboarding() {
        defaults.set(true, forKey: Self.onboardingKey)
        hasCompletedOnboarding = true
    }
}
