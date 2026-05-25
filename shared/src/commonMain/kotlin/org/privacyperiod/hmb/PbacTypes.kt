// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.hmb

/**
 * A single menstrual-flow event, the input the [PbacScorer] reads. Mirrors a
 * `flow_events` row reduced to the fields PBAC scoring uses.
 *
 * @property flowType One of pad, tampon, cup, disc, period_underwear, clot, flooding.
 * @property saturation Product saturation: light, moderate, heavy, soaked (or null).
 * @property clotSize Clot size: small or large (or null).
 * @property measuredMl Directly measured volume in millilitres for cups/discs (or null).
 */
data class FlowEventInput(
    val flowType: String,
    val saturation: String?,
    val clotSize: String?,
    val measuredMl: Double?,
)

/**
 * A cycle's heavy-bleeding classification.
 *
 * Heavy menstrual bleeding (HMB) corresponds to objective blood loss above ~80 mL;
 * PBAC approximates that with a points threshold. [BORDERLINE] flags the
 * lower screening cutoff. [INSUFFICIENT] means no flow was logged for the cycle.
 */
enum class HmbClassification { INSUFFICIENT, NORMAL, BORDERLINE, HEAVY }

/**
 * The PBAC result for one cycle.
 *
 * @property pbacPoints Summed PBAC points from pads, tampons, clots, and flooding.
 * @property measuredMl Summed directly-measured volume (cups/discs), in millilitres.
 * @property hasMeasured Whether any directly-measured volume was logged.
 * @property classification The cycle's heavy-bleeding classification.
 */
data class PbacScore(
    val pbacPoints: Int,
    val measuredMl: Double,
    val hasMeasured: Boolean,
    val classification: HmbClassification,
)
