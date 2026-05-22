// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.crypto

/**
 * In-memory [KeyStorage] for tests only.
 *
 * The key lives in heap memory, never in platform secure storage, so this must
 * never be used in production. Each generation produces distinct bytes so tests
 * can tell a regenerated key from the previous one.
 */
internal class InMemoryKeyStorage : KeyStorage {
    private var key: ByteArray? = null
    private var generation = 0

    override fun getOrCreateDatabaseKey(): ByteArray {
        val existing = key
        if (existing != null) return existing
        val generated = ByteArray(KeyStorage.DATABASE_KEY_SIZE_BYTES) { index -> (index + generation).toByte() }
        key = generated
        generation++
        return generated
    }

    override fun clearDatabaseKey() {
        key = null
    }
}
