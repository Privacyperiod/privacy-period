// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.data.db

import co.touchlab.sqliter.DatabaseFileContext
import org.privacyperiod.crypto.KeyStorage
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFails

/** A [KeyStorage] that always returns a fixed key, for deterministic tests. */
private class FixedKeyStorage(private val key: ByteArray) : KeyStorage {
    override fun getOrCreateDatabaseKey(): ByteArray = key

    override fun clearDatabaseKey() = Unit
}

/**
 * Verifies the SQLCipher-backed [DatabaseDriverFactory] on a real on-disk
 * database: that data round-trips with the correct key, and that the wrong key
 * cannot read it (proving the file is genuinely encrypted).
 */
class EncryptedDatabaseTest {
    @BeforeTest
    fun setUp() = DatabaseFileContext.deleteDatabase(TEST_DB_NAME)

    @AfterTest
    fun tearDown() = DatabaseFileContext.deleteDatabase(TEST_DB_NAME)

    @Test
    fun cycleEntryRoundTripsThroughTheEncryptedDatabase() {
        val driver = DatabaseDriverFactory(FixedKeyStorage(keyA()), TEST_DB_NAME).create()
        try {
            val database = PrivacyPeriodDatabase(driver)
            database.cycleEntriesQueries.insertCycleEntry(
                id = "cycle-a",
                start_date = "2026-02-01",
                end_date = "2026-02-05",
                flow_intensity = "LIGHT",
                notes = null,
                predicted_next = null,
                created_at = CREATED_AT,
            )
            val entries = database.cycleEntriesQueries.selectAllCycleEntries().executeAsList()
            assertEquals(1, entries.size)
            assertEquals("2026-02-01", entries.first().start_date)
        } finally {
            driver.close()
        }
    }

    @Test
    fun aWrongKeyCannotReadTheEncryptedDatabase() {
        val writer = DatabaseDriverFactory(FixedKeyStorage(keyA()), TEST_DB_NAME).create()
        PrivacyPeriodDatabase(writer).cycleEntriesQueries.insertCycleEntry(
            id = "cycle-b",
            start_date = "2026-03-01",
            end_date = null,
            flow_intensity = "HEAVY",
            notes = null,
            predicted_next = null,
            created_at = CREATED_AT,
        )
        writer.close()

        // Opening the same file with a different key must fail rather than read data.
        assertFails {
            val reader = DatabaseDriverFactory(FixedKeyStorage(keyB()), TEST_DB_NAME).create()
            PrivacyPeriodDatabase(reader).cycleEntriesQueries.selectAllCycleEntries().executeAsList()
        }
    }

    private companion object {
        const val TEST_DB_NAME = "encryption-test.db"
        const val CREATED_AT = 1_700_000_000_000L

        fun keyA() = ByteArray(KeyStorage.DATABASE_KEY_SIZE_BYTES) { 0x11 }

        fun keyB() = ByteArray(KeyStorage.DATABASE_KEY_SIZE_BYTES) { 0x22 }
    }
}
