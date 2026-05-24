// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import app.cash.sqldelight.db.SqlDriver
import org.privacyperiod.clinical.ClinicalRepository
import org.privacyperiod.clinical.IsoDate
import org.privacyperiod.clinical.SymptomEntry
import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.createTestDriver
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Exercises the PMDD module end to end on the universal layer: DRSP ratings
 * written through the repository, read back via ClinicalHistory, mapped to cycle
 * days, and scored — verifying the same answer the standalone scorer gives.
 */
class PmddModuleTest {
    private lateinit var driver: SqlDriver
    private lateinit var database: PrivacyPeriodDatabase
    private lateinit var repository: ClinicalRepository

    private val meetingItems = listOf(1, 4, 5, 7, 9, 10)

    @BeforeTest
    fun setUp() {
        driver = createTestDriver()
        database = PrivacyPeriodDatabase(driver)
        repository = ClinicalRepository(database)
        repository.seedCatalog()
    }

    @AfterTest
    fun tearDown() {
        driver.close()
    }

    private fun addCycle(id: String, startEpochDay: Int) {
        database.cycleEntriesQueries.insertCycleEntry(
            id = id,
            start_date = IsoDate.fromEpochDay(startEpochDay),
            end_date = null,
            flow_intensity = "MEDIUM",
            notes = null,
            predicted_next = null,
            created_at = 0L,
        )
    }

    private fun rate(item: Int, epochDay: Int, severity: Double, sameDay: Boolean = true) {
        repository.saveSymptomEntry(
            SymptomEntry(
                id = "drsp_$item-$epochDay",
                symptomId = "drsp_$item",
                date = IsoDate.fromEpochDay(epochDay),
                severity = severity,
                cycleId = null,
                cyclePhase = null,
                cycleDay = null,
                sameDayLogged = sameDay,
                notes = null,
                createdAt = 0L,
            ),
        )
    }

    // The textbook PMDD pattern: high pre-menstrual ratings clearing post-menstrually
    // across six DSM-5 domains, for two cycles.
    private fun loadTwoCyclePmddPattern(sameDay: Boolean = true) {
        val onset1 = IsoDate.toEpochDay("2026-01-01")!!
        val onset2 = onset1 + 28
        addCycle("c1", onset1)
        addCycle("c2", onset2)
        for (onset in listOf(onset1, onset2)) {
            for (item in meetingItems) {
                for (offset in -7..-1) rate(item, onset + offset, 6.0, sameDay)
                for (offset in 4..10) rate(item, onset + offset, 1.0, sameDay)
            }
        }
    }

    @Test
    fun twoCyclePmddPatternScoresPmddThroughTheModule() {
        loadTwoCyclePmddPattern()
        val result = (PmddModule.runScoring(repository.history()) as PmddScoringResult).result
        assertEquals(SubjectClassification.PMDD, result.subjects.single().classification)
    }

    @Test
    fun readinessReflectsScoredCycleCount() {
        loadTwoCyclePmddPattern()
        val readiness = PmddModule.checkReadiness(repository.history())
        assertEquals(2, readiness.scoredCycles)
        assertTrue(readiness.isReady)
    }

    @Test
    fun backdatedEntriesAreExcludedBySameDayEnforcement() {
        // Same pattern, but every rating is backdated — none should count.
        loadTwoCyclePmddPattern(sameDay = false)
        val result = (PmddModule.runScoring(repository.history()) as PmddScoringResult).result
        // No same-day entries means no scored cycles and no subject classification.
        assertTrue(result.cycles.none { it.included })
        assertNull(result.subjects.singleOrNull()?.classification)
    }
}
