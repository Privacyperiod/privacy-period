// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.clinical

/**
 * A clinical module: a consumer of the universal data layer, not a storage owner.
 *
 * A module declares the symptoms it needs, how ready the data is to score, and
 * how to score it. It reads through [ClinicalHistory] and never touches the
 * database directly. This is the abstraction that lets new conditions (PME, HMB,
 * endometriosis, …) be added without new storage.
 */
interface ClinicalModule {
    /** Stable identifier, e.g. "pmdd" or "pme". */
    val id: String

    /** i18n key for the module's display name. */
    val nameKey: String

    /** Stable `symptom_definitions` ids the module requires for scoring. */
    val requiredSymptoms: Set<String>

    /** Whether only same-day (prospective) entries count toward scoring. */
    val sameDayEnforced: Boolean

    /** Minimum number of scored cycles before a result is meaningful. */
    val minimumCyclesForScoring: Int

    /** Whether [history] holds enough data to produce a meaningful result. */
    fun checkReadiness(history: ClinicalHistory): ReadinessResult

    /** Runs the module's scoring over [history]. Deterministic. */
    fun runScoring(history: ClinicalHistory): ScoringResult
}

/**
 * Whether a module has enough data to score.
 *
 * @property isReady True when [scoredCycles] meets the module's minimum.
 * @property scoredCycles The number of cycles with enough data to score.
 */
data class ReadinessResult(val isReady: Boolean, val scoredCycles: Int)

/** Marker for a module's scoring output; each module returns its own subtype. */
interface ScoringResult
