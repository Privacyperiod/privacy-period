// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.data.db

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import co.touchlab.sqliter.DatabaseConfiguration
import org.privacyperiod.crypto.KeyStorage

/**
 * Creates the encrypted [SqlDriver] for the on-device database on iOS.
 *
 * The database file is encrypted with SQLCipher. The 256-bit key from
 * [KeyStorage] (the iOS Keychain) is hex-encoded and supplied as SQLCipher's key
 * through the driver's encryption configuration, which applies it before any
 * other access to the database — the only correct point to key a SQLCipher
 * connection. SQLCipher derives the page key from it with PBKDF2-HMAC-SHA-512.
 *
 * SQLCipher itself is linked into the app build (via Swift Package Manager); this
 * factory only supplies the key and opens the database.
 *
 * @property keyStorage Source of the database key (the Keychain in production).
 */
public class DatabaseDriverFactory(private val keyStorage: KeyStorage) {
    /**
     * Opens the encrypted database, creating it on first use, and returns a ready
     * [SqlDriver]. The caller owns the driver and must close it when done.
     */
    public fun create(): SqlDriver {
        val key = keyStorage.getOrCreateDatabaseKey().toHexString()
        return NativeSqliteDriver(
            schema = PrivacyPeriodDatabase.Schema,
            name = DATABASE_NAME,
            onConfiguration = { configuration ->
                configuration.copy(encryptionConfig = DatabaseConfiguration.Encryption(key = key))
            },
        )
    }

    private fun ByteArray.toHexString(): String =
        buildString(size * HEX_CHARS_PER_BYTE) {
            for (byte in this@toHexString) {
                val unsigned = byte.toInt() and BYTE_MASK
                append(unsigned.toString(HEX_RADIX).padStart(HEX_CHARS_PER_BYTE, '0'))
            }
        }

    private companion object {
        const val DATABASE_NAME: String = "privacyperiod.db"
        const val HEX_RADIX: Int = 16
        const val BYTE_MASK: Int = 0xFF
        const val HEX_CHARS_PER_BYTE: Int = 2
    }
}
