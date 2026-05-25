// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.hmb

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Tests the clean-room PBAC scorer against the published Higham et al. (1990)
 * point values and the heavy/borderline cutoffs.
 */
class PbacScorerTest {
    private fun pad(saturation: String) = FlowEventInput("pad", saturation, null, null)

    private fun tampon(saturation: String) = FlowEventInput("tampon", saturation, null, null)

    private fun clot(size: String) = FlowEventInput("clot", null, size, null)

    @Test
    fun noEventsIsInsufficient() {
        val score = PbacScorer.scoreCycle(emptyList())
        assertEquals(0, score.pbacPoints)
        assertEquals(HmbClassification.INSUFFICIENT, score.classification)
    }

    @Test
    fun padPointsFollowHigham() {
        // light 1 + moderate 5 + saturated 20 = 26.
        val score = PbacScorer.scoreCycle(listOf(pad("light"), pad("moderate"), pad("soaked")))
        assertEquals(26, score.pbacPoints)
        assertEquals(HmbClassification.NORMAL, score.classification)
    }

    @Test
    fun tamponPointsFollowHigham() {
        // light 1 + moderate 5 + saturated 10 = 16.
        val score = PbacScorer.scoreCycle(listOf(tampon("light"), tampon("moderate"), tampon("soaked")))
        assertEquals(16, score.pbacPoints)
    }

    @Test
    fun clotPointsFollowHigham() {
        val score = PbacScorer.scoreCycle(listOf(clot("small"), clot("large")))
        assertEquals(6, score.pbacPoints)
    }

    @Test
    fun floodingScoresFivePoints() {
        val score = PbacScorer.scoreCycle(listOf(FlowEventInput("flooding", null, null, null)))
        assertEquals(5, score.pbacPoints)
    }

    @Test
    fun heavyAndSoakedBothMapToSaturated() {
        // Both past "moderate" → saturated pad (20) each.
        val score = PbacScorer.scoreCycle(listOf(pad("heavy"), pad("soaked")))
        assertEquals(40, score.pbacPoints)
    }

    @Test
    fun periodUnderwearScoresAsPad() {
        val score = PbacScorer.scoreCycle(listOf(FlowEventInput("period_underwear", "soaked", null, null)))
        assertEquals(20, score.pbacPoints)
    }

    @Test
    fun reachingPrimaryCutoffIsHeavy() {
        // 5 saturated pads = 100.
        val score = PbacScorer.scoreCycle(List(5) { pad("soaked") })
        assertEquals(100, score.pbacPoints)
        assertEquals(HmbClassification.HEAVY, score.classification)
    }

    @Test
    fun secondaryCutoffIsBorderline() {
        // 3 saturated (60) + 3 moderate (15) + 1 light (1) = 76.
        val events = List(3) { pad("soaked") } + List(3) { pad("moderate") } + listOf(pad("light"))
        val score = PbacScorer.scoreCycle(events)
        assertEquals(76, score.pbacPoints)
        assertEquals(HmbClassification.BORDERLINE, score.classification)
    }

    @Test
    fun justBelowSecondaryCutoffIsNormal() {
        // 75 points: 3 saturated (60) + 3 moderate (15).
        val events = List(3) { pad("soaked") } + List(3) { pad("moderate") }
        val score = PbacScorer.scoreCycle(events)
        assertEquals(75, score.pbacPoints)
        assertEquals(HmbClassification.NORMAL, score.classification)
    }

    @Test
    fun measuredVolumeTriggersHeavyIndependentOfPoints() {
        val score = PbacScorer.scoreCycle(listOf(FlowEventInput("cup", null, null, 90.0)))
        assertEquals(0, score.pbacPoints)
        assertEquals(90.0, score.measuredMl)
        assertTrue(score.hasMeasured)
        assertEquals(HmbClassification.HEAVY, score.classification)
    }

    @Test
    fun unknownSaturationScoresNothing() {
        val score = PbacScorer.scoreCycle(listOf(pad("unknown")))
        assertEquals(0, score.pbacPoints)
    }
}
