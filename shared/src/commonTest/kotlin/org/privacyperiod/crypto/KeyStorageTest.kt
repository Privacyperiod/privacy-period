// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.crypto

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Contract tests for [KeyStorage], exercised through the in-memory test double.
 * The Keychain-backed implementation is verified via the app, since the iOS
 * Keychain is not reliably available to a plain unit-test binary.
 */
class KeyStorageTest {
    @Test
    fun keyIs256Bits() {
        val storage = InMemoryKeyStorage()
        assertEquals(KeyStorage.DATABASE_KEY_SIZE_BYTES, storage.getOrCreateDatabaseKey().size)
    }

    @Test
    fun returnsTheSameKeyOnRepeatedCalls() {
        val storage = InMemoryKeyStorage()
        val first = storage.getOrCreateDatabaseKey()
        val second = storage.getOrCreateDatabaseKey()
        assertTrue(first.contentEquals(second))
    }

    @Test
    fun generatesADifferentKeyAfterClear() {
        val storage = InMemoryKeyStorage()
        val first = storage.getOrCreateDatabaseKey()
        storage.clearDatabaseKey()
        val regenerated = storage.getOrCreateDatabaseKey()
        assertEquals(KeyStorage.DATABASE_KEY_SIZE_BYTES, regenerated.size)
        assertFalse(first.contentEquals(regenerated))
    }
}
