// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.endo

/**
 * The single switch that gates the EHP-30 (Endometriosis Health Profile)
 * quality-of-life module — the licensed clinical instrument.
 *
 * EHP-30 is licensed by Oxford University Innovation. Unlike the screening score,
 * its 30 items and subscale scoring cannot be reproduced here without that
 * licence, so this module is a **scaffold**: [EhpModule] reads EHP-30 instrument
 * completions and the official items + scoring drop in as a separately-licensed
 * asset once the licence is obtained. Until then there is nothing to score.
 *
 * This flag stays [isEnabled]` = false` until both the licence and clinical
 * sign-off are in place. It never states a diagnosis.
 */
object EhpFeature {
    /**
     * Whether the EHP-30 UI is reachable. Stays false pending the Oxford licence
     * and clinical sign-off. Read from Swift as `EhpFeature.shared.isEnabled`.
     */
    @Suppress("MayBeConst")
    val isEnabled: Boolean = false
}
