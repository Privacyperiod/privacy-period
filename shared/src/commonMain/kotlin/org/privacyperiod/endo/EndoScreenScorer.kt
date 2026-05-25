// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.endo

/**
 * The endometriosis screening scorer — a clean-room implementation of the
 * validated patient-questionnaire scores published by Chauvet et al. (2021),
 * *eClinicalMedicine* (CC BY-NC-ND 4.0).
 *
 * It computes two published weighted scores from self-reported risk factors and
 * VAS symptom intensities, and bands each into a screening risk level. It is a
 * *screening* score — it estimates whether discussing endometriosis with a
 * clinician may be warranted — and **never** states a diagnosis.
 *
 * The numeric weights and thresholds below are the published method (facts);
 * the official questionnaire item *wording* is a separately-licensed asset kept
 * out of this repository, surfaced via paraphrase labels and the tap-to-define
 * flow. The module stays gated until clinical sign-off.
 */
object EndoScreenScorer {
    // "Score 1" (8-item) point weights — Chauvet et al. (2021), Table 3.
    private const val S1_FAMILY = 14
    private const val S1_INFERTILITY = 6
    private const val S1_BMI = 7
    private const val S1_CYCLE = 4
    private const val S1_DYSMENORRHEA = 11
    private const val S1_DYSPAREUNIA = 6
    private const val S1_GI = 14
    private const val S1_URINARY = 12

    // "Score 2" (5-item) point weights.
    private const val S2_FAMILY = 17
    private const val S2_INFERTILITY = 5
    private const val S2_BMI = 7
    private const val S2_CYCLE = 2
    private const val S2_DYSMENORRHEA = 17

    // VAS thresholds at or above which a symptom contributes.
    private const val VAS_DYSMENORRHEA = 6
    private const val VAS_DYSPAREUNIA = 3
    private const val VAS_GI = 5
    private const val VAS_URINARY = 1

    // Score 1 risk bands (Table 4a): <11 low, 18–24 high, ≥25 very high.
    private const val S1_LOW_MAX = 10
    private const val S1_HIGH_MIN = 18
    private const val S1_VERY_HIGH_MIN = 25

    // Score 2 risk bands (Table 4b): <7 low, 17–23 high, ≥24 very high.
    private const val S2_LOW_MAX = 6
    private const val S2_HIGH_MIN = 17
    private const val S2_VERY_HIGH_MIN = 24

    /** Computes both published scores and their risk bands. */
    fun score(inputs: EndoScreenInputs): EndoScreenResult {
        val brief = score2(inputs)
        val extended = score1(inputs)
        return EndoScreenResult(
            briefScore = brief,
            briefRisk = band(brief, S2_LOW_MAX, S2_HIGH_MIN, S2_VERY_HIGH_MIN),
            extendedScore = extended,
            extendedRisk = band(extended, S1_LOW_MAX, S1_HIGH_MIN, S1_VERY_HIGH_MIN),
        )
    }

    private fun score1(inputs: EndoScreenInputs): Int =
        pts(inputs.familyHistory, S1_FAMILY) +
            pts(inputs.primaryInfertility, S1_INFERTILITY) +
            pts(inputs.bmiUnder22, S1_BMI) +
            pts(inputs.cyclesUnder28, S1_CYCLE) +
            pts(atLeast(inputs.vasDysmenorrhea, VAS_DYSMENORRHEA), S1_DYSMENORRHEA) +
            pts(atLeast(inputs.vasDeepDyspareunia, VAS_DYSPAREUNIA), S1_DYSPAREUNIA) +
            pts(atLeast(inputs.vasGiSymptoms, VAS_GI), S1_GI) +
            pts(atLeast(inputs.vasUrinarySymptoms, VAS_URINARY), S1_URINARY)

    private fun score2(inputs: EndoScreenInputs): Int =
        pts(inputs.familyHistory, S2_FAMILY) +
            pts(inputs.primaryInfertility, S2_INFERTILITY) +
            pts(inputs.bmiUnder22, S2_BMI) +
            pts(inputs.cyclesUnder28, S2_CYCLE) +
            pts(atLeast(inputs.vasDysmenorrhea, VAS_DYSMENORRHEA), S2_DYSMENORRHEA)

    private fun band(score: Int, lowMax: Int, highMin: Int, veryHighMin: Int): EndoRiskLevel =
        when {
            score >= veryHighMin -> EndoRiskLevel.VERY_HIGH
            score >= highMin -> EndoRiskLevel.HIGH
            score <= lowMax -> EndoRiskLevel.LOW
            else -> EndoRiskLevel.INTERMEDIATE
        }

    private fun pts(condition: Boolean, weight: Int): Int = if (condition) weight else 0

    private fun atLeast(vas: Int?, threshold: Int): Boolean = (vas ?: 0) >= threshold
}
