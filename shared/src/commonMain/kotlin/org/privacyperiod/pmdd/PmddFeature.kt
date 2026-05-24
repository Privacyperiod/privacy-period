// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

/**
 * The single switch that gates the PMDD premenstrual-symptom screening feature.
 *
 * The C-PASS scoring engine ([CpassScorer]) is built and tested, but the
 * user-facing screening — daily DRSP entry, results, and export — must not be
 * reachable in shipped builds until it has been clinically reviewed and signed
 * off. See `docs/clinical-disclaimer.md` for the gating policy and the rules the
 * feature must follow (above all: it never states a diagnosis).
 *
 * This flag stays [isEnabled]` = false` until that sign-off is complete. The UI
 * must hide every PMDD entry point when it is false. Flipping it on is the action
 * that the signed clinical disclaimer authorizes.
 */
object PmddFeature {
    /**
     * Whether the PMDD screening UI is reachable. Stays false pending sign-off.
     *
     * Kept as a property (not a `const`) so it reads from Swift as
     * `PmddFeature.shared.isEnabled` and can later become runtime-configurable.
     */
    @Suppress("MayBeConst")
    val isEnabled: Boolean = false
}
