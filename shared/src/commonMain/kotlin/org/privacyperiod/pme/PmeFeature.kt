// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pme

/**
 * The single switch that gates the PME (premenstrual exacerbation) screening.
 *
 * The PMDD-vs-PME differentiation and the MAC-PMSS tracking are built and tested,
 * but the user-facing screening — the daily mood-chart entry, the pattern result,
 * and the export — must not be reachable in shipped builds until clinical and
 * safety review is signed off. The mood chart also depends on the licensed
 * MAC-PMSS instrument (see `instrument-licensing.md`), and the screen carries a
 * suicidal-ideation item that requires specialist safety review.
 *
 * This flag stays [isEnabled]` = false` until that sign-off is complete. The UI
 * must hide every PME entry point when it is false. It never states a diagnosis.
 */
object PmeFeature {
    /**
     * Whether the PME screening UI is reachable. Stays false pending sign-off.
     *
     * Kept as a property (not a `const`) so it reads from Swift as
     * `PmeFeature.shared.isEnabled` and can later become runtime-configurable.
     */
    @Suppress("MayBeConst")
    val isEnabled: Boolean = false
}
