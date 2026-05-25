// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.hmb

/**
 * The Pictorial Blood Loss Assessment Chart (PBAC) scorer — a clean-room
 * implementation of the published Higham et al. (1990) scoring, used by the Heavy
 * Menstrual Bleeding module.
 *
 * It sums points per cycle from pads, tampons, clots, and flooding, and sums any
 * directly-measured volume from cups/discs separately. A cycle is classified
 * [HmbClassification.HEAVY] when the PBAC total reaches [PRIMARY_CUTOFF] **or** the
 * measured volume reaches [MEASURED_ML_HMB] (≈ the >80 mL objective definition of
 * heavy menstrual bleeding); [HmbClassification.BORDERLINE] at the lower
 * [SECONDARY_CUTOFF] screening threshold.
 *
 * Fidelity notes (pending clinical sign-off; the module is gated):
 * - PBAC defines three product tiers (lightly stained, moderately soiled,
 *   completely saturated). The data model records four saturation tokens; "heavy"
 *   and "soaked" both map to the saturated tier, since anything past "moderately
 *   soiled" scores as saturated in PBAC.
 * - Period underwear is not in the original PBAC; it is scored as a pad-equivalent.
 * - This scorer never states a diagnosis; it produces a factual classification to
 *   share with a clinician.
 */
object PbacScorer {
    // Higham et al. (1990) PBAC point values.
    private const val PAD_LIGHT = 1
    private const val PAD_MODERATE = 5
    private const val PAD_SATURATED = 20
    private const val TAMPON_LIGHT = 1
    private const val TAMPON_MODERATE = 5
    private const val TAMPON_SATURATED = 10
    private const val CLOT_SMALL = 1
    private const val CLOT_LARGE = 5
    private const val FLOODING_POINTS = 5

    /** PBAC total at or above this indicates heavy menstrual bleeding. */
    const val PRIMARY_CUTOFF: Int = 100

    /** Lower screening threshold; a total at or above this is borderline. */
    const val SECONDARY_CUTOFF: Int = 76

    /** Measured volume (mL) at or above this indicates heavy menstrual bleeding. */
    const val MEASURED_ML_HMB: Double = 80.0

    /** Scores one cycle's flow events into a [PbacScore]. */
    fun scoreCycle(events: List<FlowEventInput>): PbacScore {
        if (events.isEmpty()) {
            return PbacScore(0, 0.0, hasMeasured = false, classification = HmbClassification.INSUFFICIENT)
        }
        val points = events.sumOf { pointsFor(it) }
        val measured = events.mapNotNull { it.measuredMl }
        val measuredMl = measured.sum()
        return PbacScore(
            pbacPoints = points,
            measuredMl = measuredMl,
            hasMeasured = measured.isNotEmpty(),
            classification = classify(points, measuredMl),
        )
    }

    private fun classify(points: Int, measuredMl: Double): HmbClassification =
        when {
            points >= PRIMARY_CUTOFF || measuredMl >= MEASURED_ML_HMB -> HmbClassification.HEAVY
            points >= SECONDARY_CUTOFF -> HmbClassification.BORDERLINE
            else -> HmbClassification.NORMAL
        }

    private fun pointsFor(event: FlowEventInput): Int =
        when (event.flowType) {
            "pad", "period_underwear" -> padPoints(event.saturation)
            "tampon" -> tamponPoints(event.saturation)
            "clot" -> clotPoints(event.clotSize)
            "flooding" -> FLOODING_POINTS
            else -> 0 // cup/disc are measured directly; unknown types score nothing
        }

    private fun padPoints(saturation: String?): Int =
        when (saturationTier(saturation)) {
            Tier.LIGHT -> PAD_LIGHT
            Tier.MODERATE -> PAD_MODERATE
            Tier.SATURATED -> PAD_SATURATED
            Tier.NONE -> 0
        }

    private fun tamponPoints(saturation: String?): Int =
        when (saturationTier(saturation)) {
            Tier.LIGHT -> TAMPON_LIGHT
            Tier.MODERATE -> TAMPON_MODERATE
            Tier.SATURATED -> TAMPON_SATURATED
            Tier.NONE -> 0
        }

    private fun clotPoints(clotSize: String?): Int =
        when (clotSize) {
            "small" -> CLOT_SMALL
            "large" -> CLOT_LARGE
            else -> 0
        }

    private enum class Tier { NONE, LIGHT, MODERATE, SATURATED }

    private fun saturationTier(saturation: String?): Tier =
        when (saturation) {
            "light" -> Tier.LIGHT
            "moderate" -> Tier.MODERATE
            "heavy", "soaked" -> Tier.SATURATED
            else -> Tier.NONE
        }
}
