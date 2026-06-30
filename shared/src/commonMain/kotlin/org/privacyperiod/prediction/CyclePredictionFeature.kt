// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.prediction

/**
 * Feature flag for period timing prediction.
 *
 * This is a practical utility feature (not a clinical screening module), so it
 * requires no clinical sign-off and is always enabled. No gating required.
 */
object CyclePredictionFeature {
    @Suppress("MayBeConst")
    val isEnabled: Boolean = true
}
