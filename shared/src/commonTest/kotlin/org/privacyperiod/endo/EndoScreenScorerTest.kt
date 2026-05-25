// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.endo

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Tests the clean-room endometriosis screening scorer against the published
 * Chauvet et al. (2021) point weights, VAS thresholds, and risk bands.
 */
class EndoScreenScorerTest {
    private val none =
        EndoScreenInputs(
            familyHistory = false,
            primaryInfertility = false,
            bmiUnder22 = false,
            cyclesUnder28 = false,
            vasDysmenorrhea = null,
            vasDeepDyspareunia = null,
            vasGiSymptoms = null,
            vasUrinarySymptoms = null,
        )

    @Test
    fun noRiskFactorsIsZeroAndLow() {
        val result = EndoScreenScorer.score(none)
        assertEquals(0, result.briefScore)
        assertEquals(0, result.extendedScore)
        assertEquals(EndoRiskLevel.LOW, result.briefRisk)
        assertEquals(EndoRiskLevel.LOW, result.extendedRisk)
    }

    @Test
    fun familyHistoryAndSevereDysmenorrheaDriveBriefScore() {
        // Score 2: family 17 + dysmenorrhea(>=6) 17 = 34 → very high (>=24).
        val result = EndoScreenScorer.score(none.copy(familyHistory = true, vasDysmenorrhea = 8))
        assertEquals(34, result.briefScore)
        assertEquals(EndoRiskLevel.VERY_HIGH, result.briefRisk)
    }

    @Test
    fun vasBelowThresholdDoesNotContribute() {
        // Dysmenorrhea 5 is below the >=6 threshold → no points.
        val result = EndoScreenScorer.score(none.copy(vasDysmenorrhea = 5))
        assertEquals(0, result.briefScore)
        assertEquals(0, result.extendedScore)
    }

    @Test
    fun extendedScoreSumsAllEightItems() {
        // All factors present, all VAS at/above threshold:
        // 14 + 6 + 7 + 4 + 11 + 6 + 14 + 12 = 74.
        val result =
            EndoScreenScorer.score(
                EndoScreenInputs(
                    familyHistory = true,
                    primaryInfertility = true,
                    bmiUnder22 = true,
                    cyclesUnder28 = true,
                    vasDysmenorrhea = 6,
                    vasDeepDyspareunia = 3,
                    vasGiSymptoms = 5,
                    vasUrinarySymptoms = 1,
                ),
            )
        assertEquals(74, result.extendedScore)
        assertEquals(EndoRiskLevel.VERY_HIGH, result.extendedRisk)
    }

    @Test
    fun intermediateBandBetweenLowAndHigh() {
        // Score 2: BMI 7 + dysmenorrhea 17 = 24 → very high; use BMI + cycle for mid.
        // BMI 7 + cycle 2 + infertility 5 = 14 → between low (<7) and high (>=17).
        val result =
            EndoScreenScorer.score(
                none.copy(bmiUnder22 = true, cyclesUnder28 = true, primaryInfertility = true),
            )
        assertEquals(14, result.briefScore)
        assertEquals(EndoRiskLevel.INTERMEDIATE, result.briefRisk)
    }

    @Test
    fun highBandForExtendedScore() {
        // GI 14 + urinary 12 = 26 → wait that's very high; use family 14 + cycle 4 = 18 → high.
        val result = EndoScreenScorer.score(none.copy(familyHistory = true, cyclesUnder28 = true))
        assertEquals(18, result.extendedScore)
        assertEquals(EndoRiskLevel.HIGH, result.extendedRisk)
    }
}
