// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.prediction

import org.privacyperiod.clinical.Cycle
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class CyclePredictionEngineTest {
    private fun cycle(startDate: String) =
        Cycle(
            id = startDate,
            startDate = startDate,
            endDate = null,
            flowIntensity = "MEDIUM",
            notes = null,
            predictedNext = null,
            createdAt = 0L,
        )

    @Test
    fun `returns not ready with zero cycles`() {
        val result = CyclePredictionEngine.predict(emptyList())
        assertFalse(result.isReady)
        assertNull(result.predictedDate)
        assertEquals(MIN_LOGGED_PERIODS, result.cyclesNeeded)
    }

    @Test
    fun `returns not ready with two cycles`() {
        val result = CyclePredictionEngine.predict(listOf(cycle("2024-01-01"), cycle("2024-01-29")))
        assertFalse(result.isReady)
        assertNull(result.predictedDate)
        assertEquals(1, result.cyclesNeeded)
    }

    @Test
    fun `predicts correctly with three periods of uniform length`() {
        val result =
            CyclePredictionEngine.predict(
                listOf(
                    cycle("2024-01-01"),
                    // 28-day interval
                    cycle("2024-01-29"),
                    // 28-day interval
                    cycle("2024-02-26"),
                )
            )
        assertTrue(result.isReady)
        assertEquals("2024-03-25", result.predictedDate) // 28 days after 2024-02-26
        assertEquals(28.0, result.averageCycleDays)
        assertEquals(2, result.cyclesUsed)
        assertEquals(0, result.cyclesNeeded)
    }

    @Test
    fun `averages mixed cycle lengths`() {
        val result =
            CyclePredictionEngine.predict(
                listOf(
                    cycle("2024-01-01"),
                    // 28-day interval
                    cycle("2024-01-29"),
                    // 35-day interval
                    cycle("2024-03-04"),
                    // 28-day interval
                    cycle("2024-04-01"),
                )
            )
        assertTrue(result.isReady)
        // average = (28 + 35 + 28) / 3 = 30 (truncated from 30.33)
        assertEquals(3, result.cyclesUsed)
        assertNotNull(result.predictedDate)
    }

    @Test
    fun `uses at most six intervals from the most recent seven cycles`() {
        // 8 cycles → should still only use the last 7 → 6 intervals
        val cycles =
            (0..7).map { i ->
                cycle(dateByAddingDays("2024-01-01", i * 28))
            }
        val result = CyclePredictionEngine.predict(cycles)
        assertTrue(result.isReady)
        assertEquals(6, result.cyclesUsed)
    }

    @Test
    fun `filters out outlier intervals below 10 days`() {
        val result =
            CyclePredictionEngine.predict(
                listOf(
                    cycle("2024-01-01"),
                    // 3-day interval — filtered out
                    cycle("2024-01-04"),
                    // 28-day interval
                    cycle("2024-02-01"),
                    // 28-day interval
                    cycle("2024-02-29"),
                )
            )
        assertTrue(result.isReady)
        // Only 28+28 counted; the 3-day gap is dropped
        assertEquals(2, result.cyclesUsed)
        assertEquals(28.0, result.averageCycleDays)
    }

    @Test
    fun `filters out outlier intervals above 90 days`() {
        val result =
            CyclePredictionEngine.predict(
                listOf(
                    cycle("2024-01-01"),
                    // 100-day interval — filtered out
                    cycle("2024-04-10"),
                    // 28-day interval
                    cycle("2024-05-08"),
                    // 28-day interval
                    cycle("2024-06-05"),
                )
            )
        assertTrue(result.isReady)
        assertEquals(2, result.cyclesUsed)
        assertEquals(28.0, result.averageCycleDays)
    }

    // Simple helper: add days to an ISO date string.
    private fun dateByAddingDays(iso: String, days: Int): String {
        val epoch = org.privacyperiod.clinical.IsoDate.toEpochDay(iso) ?: return iso
        return org.privacyperiod.clinical.IsoDate.fromEpochDay(epoch + days)
    }

    companion object {
        private const val MIN_LOGGED_PERIODS = CyclePredictionEngine.MIN_LOGGED_PERIODS
    }
}
