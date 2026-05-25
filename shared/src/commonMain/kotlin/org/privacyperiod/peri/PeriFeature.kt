// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

/**
 * The single switch that gates the Perimenopause (Greene Climacteric Scale)
 * screening.
 *
 * The [GreeneScale] scorer and the [GreeneModule] are built and tested, but the
 * user-facing questionnaire and the result profile must not be reachable in
 * shipped builds until clinically reviewed and signed off. The result is never a
 * diagnosis — Greene is a symptom-severity profile with no cutoff.
 *
 * This flag stays [isEnabled]` = false` until that sign-off is complete. The UI
 * must hide every perimenopause entry point when it is false.
 */
object PeriFeature {
    /**
     * Whether the perimenopause screening UI is reachable. Stays false pending
     * sign-off. Kept as a property (not a `const`) so it reads from Swift as
     * `PeriFeature.shared.isEnabled` and can later become runtime-configurable.
     */
    @Suppress("MayBeConst")
    val isEnabled: Boolean = false
}
