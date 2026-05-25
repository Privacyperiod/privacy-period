// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.hmb

/**
 * The single switch that gates the Heavy Menstrual Bleeding (HMB) screening.
 *
 * The PBAC scorer ([PbacScorer]) and the [HmbModule] are built and tested, but the
 * user-facing screening — flow-event logging and the per-cycle result — must not be
 * reachable in shipped builds until it has been clinically reviewed and signed off.
 * Two fidelity decisions in particular need review: the mapping of the data model's
 * four saturation tokens onto PBAC's three tiers, and scoring period underwear as a
 * pad-equivalent. The result is never a diagnosis.
 *
 * This flag stays [isEnabled]` = false` until that sign-off is complete. The UI must
 * hide every HMB entry point when it is false.
 */
object HmbFeature {
    /**
     * Whether the HMB screening UI is reachable. Stays false pending sign-off.
     *
     * Kept as a property (not a `const`) so it reads from Swift as
     * `HmbFeature.shared.isEnabled` and can later become runtime-configurable.
     */
    @Suppress("MayBeConst")
    val isEnabled: Boolean = false
}
