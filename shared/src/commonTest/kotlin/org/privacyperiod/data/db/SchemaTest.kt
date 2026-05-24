// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.data.db

import app.cash.sqldelight.db.SqlDriver
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Verifies that the SQLDelight schema is created correctly and that data written
 * to it can be read back. These tests run on every platform target via the
 * platform-specific [createTestDriver] implementations.
 */
class SchemaTest {
    private lateinit var driver: SqlDriver
    private lateinit var database: PrivacyPeriodDatabase

    @BeforeTest
    fun setUp() {
        driver = createTestDriver()
        database = PrivacyPeriodDatabase(driver)
    }

    @AfterTest
    fun tearDown() {
        driver.close()
    }

    /** The freshly created schema reports the initial version. */
    @Test
    fun schemaIsAtInitialVersion() {
        assertEquals(1L, PrivacyPeriodDatabase.Schema.version)
    }

    /** Every table defined in the schema exists and is queryable when empty. */
    @Test
    fun allTablesExistAndStartEmpty() {
        assertTrue(database.cycleEntriesQueries.selectAllCycleEntries().executeAsList().isEmpty())
        assertTrue(database.moodEntriesQueries.selectAllMoodEntries().executeAsList().isEmpty())
        assertTrue(database.symptomEntriesQueries.selectAllSymptomEntries().executeAsList().isEmpty())
        assertTrue(database.symptomDefinitionsQueries.selectAllActiveSymptomDefinitions().executeAsList().isEmpty())
        assertTrue(database.birthControlEntriesQueries.selectAllBirthControlEntries().executeAsList().isEmpty())
        assertTrue(database.moduleEnrollmentsQueries.selectAllEnrollments().executeAsList().isEmpty())
        assertTrue(database.appSettingsQueries.selectAllAppSettings().executeAsList().isEmpty())
    }

    /** A cycle entry written to the database can be read back unchanged. */
    @Test
    fun cycleEntryRoundTrips() {
        database.cycleEntriesQueries.insertCycleEntry(
            start_date = "2026-01-01",
            end_date = "2026-01-05",
            flow_intensity = "MEDIUM",
            notes = "first logged cycle",
            created_at = 1_700_000_000_000L,
        )

        val entries = database.cycleEntriesQueries.selectAllCycleEntries().executeAsList()

        assertEquals(1, entries.size)
        val entry = entries.first()
        assertEquals("2026-01-01", entry.start_date)
        assertEquals("2026-01-05", entry.end_date)
        assertEquals("MEDIUM", entry.flow_intensity)
        assertEquals("first logged cycle", entry.notes)
        assertEquals(1_700_000_000_000L, entry.created_at)
    }

    /** A clinical symptom definition and entry round-trip, and re-rating the same
     *  symptom on the same day updates in place rather than inserting a duplicate. */
    @Test
    fun clinicalSymptomLayerRoundTripsAndIsUniquePerDay() {
        database.symptomDefinitionsQueries.upsertSymptomDefinition(
            id = "drsp_depressed_mood",
            name_key = "symptom.depressed_mood",
            category = "mood",
            severity_scale = "drsp_6",
            clinical_provenance = "DRSP",
            provenance_item = "DRSP-1",
            is_active = 1L,
        )

        database.symptomEntriesQueries.upsertSymptomEntry(
            id = "entry-1",
            symptom_id = "drsp_depressed_mood",
            date = "2026-05-23",
            severity = 4.0,
            cycle_id = null,
            cycle_phase = "luteal",
            cycle_day = 24L,
            same_day_logged = 1L,
            notes = null,
            created_at = 1_700_000_000_000L,
        )
        // Re-rate the same symptom on the same day: must update, not duplicate.
        database.symptomEntriesQueries.upsertSymptomEntry(
            id = "entry-2",
            symptom_id = "drsp_depressed_mood",
            date = "2026-05-23",
            severity = 6.0,
            cycle_id = null,
            cycle_phase = "luteal",
            cycle_day = 24L,
            same_day_logged = 1L,
            notes = null,
            created_at = 1_700_000_001_000L,
        )

        val entries = database.symptomEntriesQueries.selectAllSymptomEntries().executeAsList()
        assertEquals(1, entries.size)
        assertEquals(6.0, entries.first().severity)
        assertEquals("drsp_depressed_mood", entries.first().symptom_id)
    }
}
