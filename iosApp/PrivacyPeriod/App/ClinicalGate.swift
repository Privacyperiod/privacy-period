// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared

/// Whether this build reveals the gated clinical modules.
///
/// Compiled in for the Debug and Demo configurations (the `DEMO` flag, see
/// `project.yml`) so the full UI is reachable for testing and clinician review.
/// The App Store **Release** build compiles without `DEMO`, so the modules stay
/// hidden until each is clinically signed off.
enum AppConfig {
    static let revealGatedModules: Bool = {
        #if DEMO
        return true
        #else
        return false
        #endif
    }()
}

/// The per-module visibility gate the UI checks.
///
/// Each clinical module ships hidden behind its own Kotlin feature flag (off until
/// clinical/safety sign-off). A `DEMO` build *additionally* reveals it — so the
/// clinician and the team can walk the whole app — **without** un-gating the App
/// Store build. When a module is signed off, flip its Kotlin flag to ship it.
enum ClinicalGate {
    static var pmdd: Bool { PmddFeature.shared.isEnabled || AppConfig.revealGatedModules }
    static var pme: Bool { PmeFeature.shared.isEnabled || AppConfig.revealGatedModules }
    static var hmb: Bool { HmbFeature.shared.isEnabled || AppConfig.revealGatedModules }
    static var perimenopause: Bool { PeriFeature.shared.isEnabled || AppConfig.revealGatedModules }
    static var endometriosis: Bool { EndoFeature.shared.isEnabled || AppConfig.revealGatedModules }
}
