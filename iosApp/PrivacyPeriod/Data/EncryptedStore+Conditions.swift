// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Condition enrollment: which clinical conditions the user has chosen to collect
/// data on. Enrollment is what the home screen and menus surface — nothing clinical
/// appears without it. Stored in the universal `module_enrollments` layer.
///
/// The premenstrual condition is special: it maps to one of two underlying modules —
/// PMDD (DRSP only) or PME (DRSP plus the MAC-PMSS mood chart) — chosen by whether
/// the user reports an existing underlying diagnosis. Only one is ever active.
extension EncryptedStore {
    /// Whether the user is enrolled in `moduleId`.
    func isEnrolled(moduleId: String) -> Bool { repository?.enrollment(moduleId: moduleId) != nil }

    /// Enrolls or unenrolls `moduleId`, optionally recording its config (e.g. the PME
    /// underlying-condition family). No-op when the store is unavailable.
    func setEnrolled(moduleId: String, _ enabled: Bool, config: String? = nil) {
        guard let repository else { return }
        if enabled {
            repository.enroll(
                moduleId: moduleId,
                config: config,
                now: Int64(Date().timeIntervalSince1970 * 1000)
            )
        } else {
            repository.unenroll(moduleId: moduleId)
        }
    }

    /// The set of enrolled module ids among the known conditions.
    func enabledModuleIds() -> Set<String> {
        var ids: Set<String> = []
        for moduleId in Self.knownModuleIds where isEnrolled(moduleId: moduleId) { ids.insert(moduleId) }
        return ids
    }

    // MARK: - Premenstrual (the merged PMDD / PME condition)

    /// Whether the premenstrual condition is on (in either PMDD-only or PME form).
    var isPremenstrualEnabled: Bool { premenstrualSelection() != nil }

    /// The premenstrual selection: `nil` when off, `premenstrualTrackOnly` for PMDD-only,
    /// or an underlying-condition family id (e.g. "depression") for PME.
    func premenstrualSelection() -> String? {
        if let pme = repository?.enrollment(moduleId: Self.pmeModuleId) { return pme.config ?? "other" }
        if isEnrolled(moduleId: Self.pmddModuleId) { return Self.premenstrualTrackOnly }
        return nil
    }

    /// Applies a premenstrual selection. Switching between PMDD-only and PME swaps the
    /// underlying enrollment so exactly one (or neither) is active.
    func setPremenstrual(_ selection: String?) {
        guard let selection else {
            setEnrolled(moduleId: Self.pmddModuleId, false)
            setEnrolled(moduleId: Self.pmeModuleId, false)
            return
        }
        if selection == Self.premenstrualTrackOnly {
            setEnrolled(moduleId: Self.pmeModuleId, false)
            setEnrolled(moduleId: Self.pmddModuleId, true)
        } else {
            setEnrolled(moduleId: Self.pmddModuleId, false)
            setEnrolled(moduleId: Self.pmeModuleId, true, config: selection)
        }
    }

    /// The module id for the DRSP-only premenstrual form (PMDD). (PME is `pmeModuleId`.)
    static let pmddModuleId = "pmdd"
    /// The premenstrual selection sentinel meaning "track premenstrual symptoms only"
    /// (PMDD), i.e. no reported underlying condition.
    static let premenstrualTrackOnly = "none"
    /// The module ids the home screen checks to decide what to surface.
    static let knownModuleIds = ["pmdd", "pme", "hmb", "perimenopause", "endometriosis"]
}
