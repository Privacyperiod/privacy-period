// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared

/// Where a condition's tasks live in the app.
enum ConditionKind {
    /// Ongoing data collection (daily or periodic logs) — surfaced in the Tracking menu.
    case tracking
    /// A one-off / occasional risk questionnaire — surfaced in the Screening menu.
    case screening
}

/// A condition the user can choose to collect data on.
///
/// The catalog is the single source of truth for the Conditions screen and (later)
/// the home menus. It is intentionally non-diagnostic: choosing a condition turns on
/// *data collection to share with a clinician*, never a diagnosis or a screen result.
struct ConditionInfo: Identifiable {
    /// The condition-family id. For the premenstrual condition this is a UI-level id
    /// that maps onto one of two underlying modules (PMDD / PME) in the store; the
    /// others map directly to a module id.
    let id: String
    let nameKey: String
    let blurbKey: String
    let kind: ConditionKind
    let cadenceKey: String
    /// Whether this build exposes the condition. Bound to the clinical sign-off gate
    /// (`ClinicalGate`): the App Store build lists only signed-off conditions, the Demo
    /// build lists all of them.
    let isAvailable: Bool

    /// The premenstrual condition's UI id (maps to the `pmdd` or `pme` module).
    static let premenstrualId = "premenstrual"

    /// Every condition, in display order. `isAvailable` is resolved from the gate.
    static let all: [ConditionInfo] = [
        ConditionInfo(
            id: "cycle_prediction",
            nameKey: "condition.cycle_prediction.name",
            blurbKey: "condition.cycle_prediction.blurb",
            kind: .tracking,
            cadenceKey: "condition.cadence.automatic",
            isAvailable: ClinicalGate.cyclePrediction
        ),
        ConditionInfo(
            id: premenstrualId,
            nameKey: "condition.premenstrual.name",
            blurbKey: "condition.premenstrual.blurb",
            kind: .tracking,
            cadenceKey: "condition.cadence.daily",
            isAvailable: ClinicalGate.pmdd || ClinicalGate.pme
        ),
        ConditionInfo(
            id: "hmb",
            nameKey: "condition.hmb.name",
            blurbKey: "condition.hmb.blurb",
            kind: .tracking,
            cadenceKey: "condition.cadence.perevent",
            isAvailable: ClinicalGate.hmb
        ),
        ConditionInfo(
            id: "perimenopause",
            nameKey: "condition.perimenopause.name",
            blurbKey: "condition.perimenopause.blurb",
            kind: .tracking,
            cadenceKey: "condition.cadence.monthly",
            isAvailable: ClinicalGate.perimenopause
        ),
        ConditionInfo(
            id: "endometriosis",
            nameKey: "condition.endometriosis.name",
            blurbKey: "condition.endometriosis.blurb",
            kind: .screening,
            cadenceKey: "condition.cadence.occasional",
            isAvailable: ClinicalGate.endometriosis
        )
    ]

    /// The conditions this build exposes.
    static var available: [ConditionInfo] { all.filter(\.isAvailable) }
}
