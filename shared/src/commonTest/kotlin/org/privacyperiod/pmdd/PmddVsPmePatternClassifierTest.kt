// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Tests the PMDD-vs-PME differentiation across the four clinical patterns, built
 * from synthetic follicular (post-menstrual) and luteal (pre-menstrual) levels.
 */
class PmddVsPmePatternClassifierTest {
    // For each differentiating item, fill the post-menstrual window (follicular)
    // at [follicular] and the pre-menstrual window (luteal) at [luteal].
    private fun observations(follicular: Int, luteal: Int): List<DrspObservation> =
        PmddVsPmePatternClassifier.DIFFERENTIATING_ITEMS.flatMap { item ->
            (4..10).map { day -> DrspObservation(subject = 0, cycle = 1, day = day, item = item, score = follicular) } +
                (-7..-1).map { day -> DrspObservation(subject = 0, cycle = 1, day = day, item = item, score = luteal) }
        }

    @Test
    fun lowBaselineHighLutealIsPmddConsistent() {
        val result = PmddVsPmePatternClassifier.classify(observations(follicular = 1, luteal = 5))
        assertEquals(CyclicityPattern.PMDD_CONSISTENT, result.pattern)
    }

    @Test
    fun elevatedBaselineRisingFurtherIsPmeConsistent() {
        val result = PmddVsPmePatternClassifier.classify(observations(follicular = 3, luteal = 5))
        assertEquals(CyclicityPattern.PME_CONSISTENT, result.pattern)
    }

    @Test
    fun elevatedBaselineWithoutRiseIsOngoingCondition() {
        val result = PmddVsPmePatternClassifier.classify(observations(follicular = 4, luteal = 4))
        assertEquals(CyclicityPattern.ONGOING_NO_CYCLICAL_CHANGE, result.pattern)
    }

    @Test
    fun lowInBothPhasesIsNoCyclicalPattern() {
        val result = PmddVsPmePatternClassifier.classify(observations(follicular = 1, luteal = 1))
        assertEquals(CyclicityPattern.NO_CYCLICAL_PATTERN, result.pattern)
    }

    @Test
    fun perSymptomDetailIsReported() {
        val result = PmddVsPmePatternClassifier.classify(observations(follicular = 1, luteal = 5))
        assertEquals(PmddVsPmePatternClassifier.DIFFERENTIATING_ITEMS.size, result.symptoms.size)
        val depressed = result.symptoms.single { it.item == 1 }
        assertEquals(1.0, depressed.follicularMean)
        assertEquals(5.0, depressed.lutealMean)
    }
}
