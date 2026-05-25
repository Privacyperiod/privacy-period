// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

import app.cash.sqldelight.db.SqlDriver
import org.privacyperiod.clinical.ClinicalRepository
import org.privacyperiod.clinical.InstrumentCompletion
import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.createTestDriver
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Exercises the Perimenopause module end to end: a Greene completion written
 * through the repository as JSON, read back via ClinicalHistory, decoded, and
 * scored into the domain profile.
 */
class GreeneModuleTest {
    private lateinit var driver: SqlDriver
    private lateinit var database: PrivacyPeriodDatabase
    private lateinit var repository: ClinicalRepository

    @BeforeTest
    fun setUp() {
        driver = createTestDriver()
        database = PrivacyPeriodDatabase(driver)
        repository = ClinicalRepository(database)
    }

    @AfterTest
    fun tearDown() {
        driver.close()
    }

    private fun addCompletion(id: String, endDate: String, responses: Map<Int, Int>) {
        repository.saveInstrumentCompletion(
            InstrumentCompletion(
                id = id,
                instrumentType = GreeneModule.INSTRUMENT_TYPE,
                startDate = endDate,
                endDate = endDate,
                itemResponsesJson = GreeneResponsesJson.encode(responses),
                computedScoresJson = null,
                createdAt = 0L,
            ),
        )
    }

    @Test
    fun noCompletionsIsNotReady() {
        val readiness = GreeneModule.checkReadiness(repository.history())
        assertFalse(readiness.isReady)
        assertEquals(0, readiness.scoredCycles)
        assertTrue((GreeneModule.runScoring(repository.history()) as GreeneScoringResult).completions.isEmpty())
    }

    @Test
    fun oneCompletionIsScoredIntoTheProfile() {
        addCompletion("g1", "2026-03-01", (1..GreeneScale.ITEM_COUNT).associateWith { 3 })

        val readiness = GreeneModule.checkReadiness(repository.history())
        assertTrue(readiness.isReady)
        assertEquals(1, readiness.scoredCycles)

        val result = GreeneModule.runScoring(repository.history()) as GreeneScoringResult
        assertEquals(1, result.completions.size)
        val profile = result.completions.first().result
        assertEquals(63, profile.total) // 21 items × 3
        assertEquals(33, profile.psychological) // anxiety 18 + depression 15
        assertTrue(profile.isComplete)
    }

    @Test
    fun completionsAreReturnedOldestFirst() {
        addCompletion("g1", "2026-01-01", mapOf(1 to 1))
        addCompletion("g2", "2026-03-01", mapOf(1 to 3))

        val result = GreeneModule.runScoring(repository.history()) as GreeneScoringResult
        assertEquals(2, result.completions.size)
        assertEquals("2026-01-01", result.completions.first().date)
        assertEquals("2026-03-01", result.completions.last().date)
    }
}
