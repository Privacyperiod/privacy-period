// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.crypto

/**
 * Symmetric authenticated-encryption primitive for data that leaves the database
 * layer — for example, encrypted backups and exports.
 *
 * Implementations use AES-256 with authenticated encryption, so decryption fails
 * on a wrong key or tampered input rather than returning garbage. This contract
 * is defined now so the data layer can depend on it; the platform implementations
 * arrive with the backup/export feature. On iOS that implementation is provided
 * from Swift via CryptoKit, because CryptoKit is not available to Kotlin/Native.
 *
 * Database-at-rest encryption does **not** go through this interface — that is
 * handled transparently by the encrypted database driver (see `docs/encryption.md`).
 */
interface CryptoProvider {
    /**
     * Generates a new random 256-bit key suitable for [encrypt] and [decrypt].
     */
    fun generateKey(): ByteArray

    /**
     * Encrypts [data] under [key].
     *
     * @param data The plaintext to protect.
     * @param key A 256-bit key, typically from [generateKey].
     * @return A self-contained ciphertext that includes the nonce and the
     *   authentication tag, safe to store or export as a single blob.
     */
    fun encrypt(data: ByteArray, key: ByteArray): ByteArray

    /**
     * Decrypts a ciphertext produced by [encrypt] under the same [key].
     *
     * @param data A ciphertext previously returned by [encrypt].
     * @param key The same key used to encrypt.
     * @return The original plaintext.
     * @throws IllegalArgumentException if authentication fails, i.e. the key is
     *   wrong or the ciphertext was modified.
     */
    fun decrypt(data: ByteArray, key: ByteArray): ByteArray
}
