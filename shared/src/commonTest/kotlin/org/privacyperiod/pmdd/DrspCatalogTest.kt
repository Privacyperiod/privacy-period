// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.createTestDriver
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Verifies the DRSP catalog and its seeding into the universal symptom layer. */
class DrspCatalogTest {
    @Test
    fun catalogHasTwentyFourDefinitionsCarryingDrspProvenance() {
        assertEquals(24, DrspCatalog.definitions.size)
        DrspCatalog.definitions.forEachIndexed { index, definition ->
            val itemNumber = index + 1
            assertEquals("drsp_$itemNumber", definition.id)
            assertEquals("DRSP", definition.clinicalProvenance)
            assertEquals("DRSP-$itemNumber", definition.provenanceItem)
            assertEquals("drsp_6", definition.severityScale)
        }
    }

    @Test
    fun stableIdAndItemNumberRoundTrip() {
        assertEquals("drsp_7", DrspCatalog.stableId(7))
        assertEquals(7, DrspCatalog.itemNumber("drsp_7"))
        assertNull(DrspCatalog.itemNumber("macpmss_mood"))
        assertNull(DrspCatalog.itemNumber("drsp_notanumber"))
    }

    @Test
    fun seedingWritesAllDefinitionsAndIsIdempotent() {
        val driver = createTestDriver()
        try {
            val database = PrivacyPeriodDatabase(driver)
            DrspCatalog.seedInto(database.symptomDefinitionsQueries)

            val rows = database.symptomDefinitionsQueries.selectAllActiveSymptomDefinitions().executeAsList()
            assertEquals(24, rows.size)
            assertTrue(rows.all { it.clinical_provenance == "DRSP" })
            assertTrue(rows.all { it.severity_scale == "drsp_6" })

            // Re-seeding updates in place rather than duplicating.
            DrspCatalog.seedInto(database.symptomDefinitionsQueries)
            assertEquals(
                24,
                database.symptomDefinitionsQueries.selectAllActiveSymptomDefinitions().executeAsList().size,
            )
        } finally {
            driver.close()
        }
    }
}
