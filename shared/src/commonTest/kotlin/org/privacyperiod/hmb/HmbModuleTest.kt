// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.hmb

import app.cash.sqldelight.db.SqlDriver
import org.privacyperiod.clinical.ClinicalRepository
import org.privacyperiod.clinical.FlowEvent
import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.createTestDriver
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Exercises the HMB module end to end on the universal layer: flow events written
 * through the repository, read back via ClinicalHistory, grouped by cycle, and
 * PBAC-scored per cycle.
 */
class HmbModuleTest {
    private lateinit var driver: SqlDriver
    private lateinit var database: PrivacyPeriodDatabase
    private lateinit var repository: ClinicalRepository
    private var eventSeq = 0

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

    private fun addCycle(id: String, startDate: String) {
        database.cycleEntriesQueries.insertCycleEntry(
            id = id,
            start_date = startDate,
            end_date = null,
            flow_intensity = "MEDIUM",
            notes = null,
            predicted_next = null,
            created_at = 0L,
        )
    }

    private fun addFlow(cycleId: String, flowType: String, saturation: String? = null) {
        repository.saveFlowEvent(
            FlowEvent(
                id = "evt-${eventSeq++}",
                cycleId = cycleId,
                eventDate = "2026-01-02",
                eventTime = null,
                flowType = flowType,
                saturation = saturation,
                clotSize = null,
                measuredMl = null,
                pbacPoints = null,
                createdAt = 0L,
            ),
        )
    }

    @Test
    fun noFlowEventsIsNotReady() {
        addCycle("c1", "2026-01-01")
        val readiness = HmbModule.checkReadiness(repository.history())
        assertFalse(readiness.isReady)
        assertEquals(0, readiness.scoredCycles)
        assertTrue((HmbModule.runScoring(repository.history()) as HmbScoringResult).cycles.isEmpty())
    }

    @Test
    fun cycleWithSaturatedPadsScoresHeavy() {
        addCycle("c1", "2026-01-01")
        repeat(5) { addFlow("c1", "pad", "soaked") } // 5 × 20 = 100

        val readiness = HmbModule.checkReadiness(repository.history())
        assertTrue(readiness.isReady)
        assertEquals(1, readiness.scoredCycles)

        val result = HmbModule.runScoring(repository.history()) as HmbScoringResult
        assertEquals(1, result.cycles.size)
        assertEquals(100, result.cycles.first().score.pbacPoints)
        assertEquals(HmbClassification.HEAVY, result.cycles.first().score.classification)
    }

    @Test
    fun onlyCyclesWithFlowAreScored() {
        addCycle("c1", "2026-01-01")
        addCycle("c2", "2026-02-01") // no flow events
        addFlow("c1", "pad", "light")

        val result = HmbModule.runScoring(repository.history()) as HmbScoringResult
        assertEquals(1, result.cycles.size)
        assertEquals("c1", result.cycles.first().cycleId)
    }

    @Test
    fun perCycleClassificationIsIndependent() {
        addCycle("c1", "2026-01-01")
        addCycle("c2", "2026-02-01")
        repeat(5) { addFlow("c1", "pad", "soaked") } // heavy
        repeat(2) { addFlow("c2", "pad", "light") } // normal

        val result = HmbModule.runScoring(repository.history()) as HmbScoringResult
        assertEquals(2, result.cycles.size)
        val byCycle = result.cycles.associateBy { it.cycleId }
        assertEquals(HmbClassification.HEAVY, byCycle.getValue("c1").score.classification)
        assertEquals(HmbClassification.NORMAL, byCycle.getValue("c2").score.classification)
    }
}
