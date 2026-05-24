// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pme

import app.cash.sqldelight.db.SqlDriver
import org.privacyperiod.clinical.ClinicalRepository
import org.privacyperiod.clinical.IsoDate
import org.privacyperiod.clinical.SymptomEntry
import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.createTestDriver
import org.privacyperiod.pmdd.CyclicityPattern
import org.privacyperiod.pmdd.PmddVsPmePatternClassifier
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Exercises the PME module end to end on the universal layer. */
class PmeModuleTest {
    private lateinit var driver: SqlDriver
    private lateinit var database: PrivacyPeriodDatabase
    private lateinit var repository: ClinicalRepository

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

    private fun rate(item: Int, epochDay: Int, severity: Double) {
        repository.saveSymptomEntry(
            SymptomEntry(
                id = "drsp_$item-$epochDay",
                symptomId = "drsp_$item",
                date = IsoDate.fromEpochDay(epochDay),
                severity = severity,
                cycleId = null,
                cyclePhase = null,
                cycleDay = null,
                sameDayLogged = true,
                notes = null,
                createdAt = 0L,
            ),
        )
    }

    @Test
    fun elevatedBaselineRisingPremenstruallyScoresPmeThroughTheModule() {
        // Two cycles where the differentiating symptoms are already elevated in
        // the follicular (post) window and rise further in the luteal (pre) window
        // — the PME pattern.
        val onset1 = IsoDate.toEpochDay("2026-01-01")!!
        val onset2 = onset1 + 28
        addCycle("c1", onset1)
        addCycle("c2", onset2)
        for (onset in listOf(onset1, onset2)) {
            for (item in PmddVsPmePatternClassifier.DIFFERENTIATING_ITEMS) {
                for (offset in -7..-1) rate(item, onset + offset, 5.0) // luteal
                for (offset in 4..10) rate(item, onset + offset, 3.0) // follicular
            }
        }

        val result = PmeModule.runScoring(repository.history()) as PmeScoringResult
        assertEquals(CyclicityPattern.PME_CONSISTENT, result.classification.pattern)
        assertTrue(PmeModule.checkReadiness(repository.history()).isReady)
    }
}
