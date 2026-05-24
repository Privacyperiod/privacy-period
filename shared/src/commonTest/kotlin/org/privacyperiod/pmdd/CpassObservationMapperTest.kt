// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Tests the calendar-to-cycle-day mapping that turns dated DRSP ratings into the
 * observations [CpassScorer] consumes, plus an end-to-end check through the scorer.
 */
class CpassObservationMapperTest {
    private fun map(scores: List<DrspDailyScore>, starts: List<Int>) =
        CpassObservationMapper.toObservations(scores, starts)

    @Test
    fun noMensesOnsetsYieldsNoObservations() {
        val result = map(listOf(DrspDailyScore(epochDay = 5, item = 1, score = 3)), starts = emptyList())
        assertTrue(result.isEmpty())
    }

    @Test
    fun postMenstrualDayIsNumberedForwardFromOnset() {
        // Onset at 100; four days later is post-menstrual day 5 of cycle 1.
        val result = map(listOf(DrspDailyScore(104, item = 1, score = 3)), starts = listOf(100, 200))
        assertEquals(1, result.size)
        assertEquals(1, result[0].cycle)
        assertEquals(5, result[0].day)
    }

    @Test
    fun preMenstrualDayIsNumberedBackwardFromNextOnset() {
        // Three days before the onset at 200 -> day -3, belonging to cycle 2.
        val result = map(listOf(DrspDailyScore(197, item = 1, score = 3)), starts = listOf(100, 200))
        assertEquals(2, result[0].cycle)
        assertEquals(-3, result[0].day)
    }

    @Test
    fun preAndPostOfTheSameOnsetShareACycle() {
        val pre = DrspDailyScore(195, item = 1, score = 3) // before onset 200
        val post = DrspDailyScore(203, item = 1, score = 3) // after onset 200
        val result = map(listOf(pre, post), starts = listOf(100, 200))
        val cycles = result.map { it.cycle }.toSet()
        assertEquals(setOf(2), cycles)
    }

    @Test
    fun theOnsetDayItselfIsDayOne() {
        val result = map(listOf(DrspDailyScore(100, item = 1, score = 3)), starts = listOf(100))
        assertEquals(1, result[0].day)
        assertEquals(1, result[0].cycle)
    }

    @Test
    fun ratingsBeforeTheFirstOnsetMapToThatCyclesPreWeek() {
        // Five days before the only onset -> day -5 of cycle 1.
        val result = map(listOf(DrspDailyScore(95, item = 1, score = 3)), starts = listOf(100))
        assertEquals(1, result[0].cycle)
        assertEquals(-5, result[0].day)
    }

    @Test
    fun datesAfterTheLastOnsetUseForwardNumbering() {
        val result = map(listOf(DrspDailyScore(108, item = 1, score = 3)), starts = listOf(100))
        assertEquals(1, result[0].cycle)
        assertEquals(9, result[0].day)
    }

    @Test
    fun mappedThenScoredPmddPatternIsClassifiedPmdd() {
        // Two cycles (onsets at 0 and 28). For six DSM-5 domains, every
        // pre-menstrual day is at the ceiling and every post-menstrual day clears
        // to the floor — the textbook PMDD pattern.
        val onsets = listOf(0, 28)
        val meetingItems = listOf(1, 4, 5, 7, 9, 10)
        val scores =
            buildList {
                for (onset in onsets) {
                    for (item in meetingItems) {
                        for (offset in -7..-1) add(DrspDailyScore(onset + offset, item, score = 6))
                        for (offset in 4..10) add(DrspDailyScore(onset + offset, item, score = 1))
                    }
                }
            }
        val result = CpassScorer.score(map(scores, onsets))
        assertEquals(SubjectClassification.PMDD, result.subjects.single().classification)
    }

    @Test
    fun theSubjectIsConstant() {
        val result = map(listOf(DrspDailyScore(104, item = 2, score = 4)), starts = listOf(100))
        assertEquals(CpassObservationMapper.SUBJECT, result[0].subject)
    }
}
