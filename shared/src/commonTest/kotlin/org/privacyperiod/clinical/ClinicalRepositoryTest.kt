// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.clinical

import app.cash.sqldelight.db.SqlDriver
import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.createTestDriver
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** Verifies the clinical repository writes and reads through the universal layer. */
class ClinicalRepositoryTest {
    private lateinit var driver: SqlDriver
    private lateinit var repository: ClinicalRepository

    @BeforeTest
    fun setUp() {
        driver = createTestDriver()
        repository = ClinicalRepository(PrivacyPeriodDatabase(driver))
        // Seed so symptom ids referenced by entries exist in the catalogue.
        repository.seedCatalog()
    }

    @AfterTest
    fun tearDown() {
        driver.close()
    }

    private fun entry(
        symptomId: String,
        date: String,
        severity: Double,
        sameDay: Boolean = true,
        id: String = "$symptomId-$date",
    ) = SymptomEntry(
        id = id,
        symptomId = symptomId,
        date = date,
        severity = severity,
        cycleId = null,
        cyclePhase = null,
        cycleDay = null,
        sameDayLogged = sameDay,
        notes = null,
        createdAt = 1_700_000_000_000L,
    )

    @Test
    fun savedEntriesAreReadBackThroughHistory() {
        repository.saveSymptomEntry(entry("drsp_1", "2026-05-23", 4.0))
        repository.saveSymptomEntry(entry("drsp_2", "2026-05-23", 2.0))

        val history = repository.history()
        assertEquals(1, history.symptomEntries(setOf("drsp_1")).size)
        assertEquals(4.0, history.symptomEntries(setOf("drsp_1")).first().severity)
        assertEquals(2, history.symptomEntries(setOf("drsp_1", "drsp_2")).size)
    }

    @Test
    fun sameDayFilterExcludesBackdatedEntries() {
        repository.saveSymptomEntry(entry("drsp_1", "2026-05-23", 4.0, sameDay = true))
        repository.saveSymptomEntry(entry("drsp_1", "2026-05-20", 3.0, sameDay = false, id = "backdated"))

        val history = repository.history()
        assertEquals(2, history.symptomEntries(setOf("drsp_1")).size)
        assertEquals(1, history.sameDaySymptomEntries(setOf("drsp_1")).size)
    }

    @Test
    fun reRatingTheSameSymptomAndDayUpdatesInPlace() {
        repository.saveSymptomEntry(entry("drsp_1", "2026-05-23", 4.0))
        repository.saveSymptomEntry(entry("drsp_1", "2026-05-23", 6.0, id = "second"))

        val entries = repository.history().symptomEntries(setOf("drsp_1"))
        assertEquals(1, entries.size)
        assertEquals(6.0, entries.first().severity)
    }
}
