// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.crypto

/**
 * Stores and retrieves the symmetric key that encrypts the on-device database.
 *
 * The key is a 256-bit value generated on first use that never leaves the device.
 * Production implementations MUST hold it in platform secure storage — the iOS
 * Keychain or the Android Keystore — and never in plain files, preferences, logs,
 * or backups. The raw key bytes are only ever handed to the database driver to
 * open the encrypted database; callers must not copy, persist, or log them.
 */
interface KeyStorage {
    /**
     * Returns the database key, generating and securely persisting a new random
     * key on the first call and returning that same key thereafter.
     *
     * @return The database key, [DATABASE_KEY_SIZE_BYTES] bytes long.
     */
    fun getOrCreateDatabaseKey(): ByteArray

    /**
     * Permanently removes the stored key, if present.
     *
     * Once the key is gone the encrypted database is unrecoverable, so this backs
     * the irreversible "delete all data" action. Implementations must treat a
     * missing key as success, not an error.
     */
    fun clearDatabaseKey()

    companion object {
        /** Length of the database key: 256 bits, expressed in bytes. */
        const val DATABASE_KEY_SIZE_BYTES: Int = 32
    }
}
