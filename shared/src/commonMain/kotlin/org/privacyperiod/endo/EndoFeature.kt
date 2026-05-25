// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.endo

/**
 * The single switch that gates the deployable (non-EHP-30) endometriosis
 * screening — the Chauvet et al. (2021) questionnaire score ([EndoScreenScorer]).
 *
 * The scorer is built and tested, but the user-facing questionnaire and its risk
 * result must not be reachable in shipped builds until clinically reviewed and
 * signed off. The result is a screening estimate — whether discussing
 * endometriosis with a clinician may be worth it — and never a diagnosis. Unlike
 * EHP-30 ([EhpFeature]) this path needs no instrument licence, only sign-off.
 *
 * This flag stays [isEnabled]` = false` until that sign-off is complete.
 */
object EndoFeature {
    /**
     * Whether the endometriosis screening UI is reachable. Stays false pending
     * sign-off. Kept as a property (not a `const`) so it reads from Swift as
     * `EndoFeature.shared.isEnabled` and can later become runtime-configurable.
     */
    @Suppress("MayBeConst")
    val isEnabled: Boolean = false
}
