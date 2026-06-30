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
    var isPremenstrualEnabled: Bool {
        isEnrolled(moduleId: Self.pmddModuleId) || isEnrolled(moduleId: Self.pmeModuleId)
    }

    /// The self-reported diagnosed underlying conditions for the premenstrual module.
    /// Empty means PMDD-only (track premenstrual symptoms with no underlying condition)
    /// or off. More than one is allowed — comorbidity is common.
    func premenstrualFamilies() -> Set<String> {
        guard let config = repository?.enrollment(moduleId: Self.pmeModuleId)?.config else { return [] }
        return Set(config.split(separator: ",").map(String.init))
    }

    /// Applies a premenstrual selection. With no families it enrolls PMDD (DRSP only);
    /// with one or more it enrolls PME (DRSP + the MAC-PMSS mood chart), recording the
    /// families as a comma-separated config. Only one underlying module is ever active.
    func setPremenstrual(enabled: Bool, families: Set<String>) {
        guard enabled else {
            setEnrolled(moduleId: Self.pmddModuleId, false)
            setEnrolled(moduleId: Self.pmeModuleId, false)
            return
        }
        if families.isEmpty {
            setEnrolled(moduleId: Self.pmeModuleId, false)
            setEnrolled(moduleId: Self.pmddModuleId, true)
        } else {
            setEnrolled(moduleId: Self.pmddModuleId, false)
            setEnrolled(moduleId: Self.pmeModuleId, true, config: families.sorted().joined(separator: ","))
        }
    }

    /// The module id for the DRSP-only premenstrual form (PMDD). (PME is `pmeModuleId`.)
    static let pmddModuleId = "pmdd"
    /// The module id for period timing prediction.
    static let cyclePredictionModuleId = "cycle_prediction"
    /// The module ids the home screen checks to decide what to surface.
    static let knownModuleIds = ["pmdd", "pme", "hmb", "perimenopause", "endometriosis", "cycle_prediction"]
}
