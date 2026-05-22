// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.crypto

import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.alloc
import kotlinx.cinterop.convert
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.value
import platform.CoreFoundation.CFDictionaryAddValue
import platform.CoreFoundation.CFDictionaryCreateMutable
import platform.CoreFoundation.CFMutableDictionaryRef
import platform.CoreFoundation.CFRelease
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFBooleanTrue
import platform.CoreFoundation.kCFTypeDictionaryKeyCallBacks
import platform.CoreFoundation.kCFTypeDictionaryValueCallBacks
import platform.Foundation.CFBridgingRelease
import platform.Foundation.CFBridgingRetain
import platform.Foundation.NSData
import platform.Foundation.create
import platform.Security.SecItemAdd
import platform.Security.SecItemCopyMatching
import platform.Security.SecItemDelete
import platform.Security.SecRandomCopyBytes
import platform.Security.errSecSuccess
import platform.Security.kSecAttrAccessible
import platform.Security.kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
import platform.Security.kSecAttrAccount
import platform.Security.kSecAttrService
import platform.Security.kSecClass
import platform.Security.kSecClassGenericPassword
import platform.Security.kSecMatchLimit
import platform.Security.kSecMatchLimitOne
import platform.Security.kSecRandomDefault
import platform.Security.kSecReturnData
import platform.Security.kSecValueData
import platform.posix.memcpy

/**
 * [KeyStorage] backed by the iOS Keychain.
 *
 * The key is stored as a generic-password item protected with
 * `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`:
 * - *AfterFirstUnlock* keeps the key available for background work (such as
 *   scheduling local notifications) after the user has unlocked the device once
 *   since boot, while denying access before the first unlock.
 * - *ThisDeviceOnly* keeps the key out of iCloud Keychain and device backups, so
 *   it can never follow the encrypted data off this device.
 *
 * The raw key bytes are only ever returned to the database driver to open the
 * encrypted database; they are never logged or persisted elsewhere. See
 * `docs/encryption.md` for the full model.
 */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
public class KeychainKeyStorage(
    private val service: String = DEFAULT_SERVICE,
    private val account: String = DEFAULT_ACCOUNT,
) : KeyStorage {
    override fun getOrCreateDatabaseKey(): ByteArray {
        readExistingKey()?.let { return it }
        val key = generateRandomKey()
        storeKey(key)
        return key
    }

    override fun clearDatabaseKey() {
        val query = baseQuery()
        // A missing item is success for our purposes, so the status is ignored.
        SecItemDelete(query)
        CFRelease(query)
    }

    private fun readExistingKey(): ByteArray? =
        memScoped {
            val query = baseQuery()
            CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue)
            CFDictionaryAddValue(query, kSecMatchLimit, kSecMatchLimitOne)
            val result = alloc<CFTypeRefVar>()
            val status = SecItemCopyMatching(query, result.ptr)
            CFRelease(query)
            if (status != errSecSuccess) return@memScoped null
            // CFBridgingRelease transfers ownership of the copied data to ARC.
            val data = CFBridgingRelease(result.value) as? NSData ?: return@memScoped null
            data.toByteArray()
        }

    private fun storeKey(key: ByteArray) {
        val query = baseQuery()
        val data = CFBridgingRetain(key.toNSData())
        CFDictionaryAddValue(query, kSecValueData, data)
        CFDictionaryAddValue(
            query,
            kSecAttrAccessible,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        )
        val status = SecItemAdd(query, null)
        CFRelease(data)
        CFRelease(query)
        check(status == errSecSuccess) { "Keychain write failed (OSStatus=$status)" }
    }

    private fun generateRandomKey(): ByteArray {
        val key = ByteArray(KeyStorage.DATABASE_KEY_SIZE_BYTES)
        val status =
            key.usePinned { pinned ->
                SecRandomCopyBytes(kSecRandomDefault, key.size.convert(), pinned.addressOf(0))
            }
        check(status == errSecSuccess) { "Secure random generation failed (OSStatus=$status)" }
        return key
    }

    private fun baseQuery(): CFMutableDictionaryRef {
        val query =
            CFDictionaryCreateMutable(
                null,
                0,
                kCFTypeDictionaryKeyCallBacks.ptr,
                kCFTypeDictionaryValueCallBacks.ptr,
            ) ?: error("Unable to allocate Keychain query dictionary")
        CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword)
        val serviceRef = CFBridgingRetain(service)
        val accountRef = CFBridgingRetain(account)
        CFDictionaryAddValue(query, kSecAttrService, serviceRef)
        CFDictionaryAddValue(query, kSecAttrAccount, accountRef)
        // The dictionary retains its values, so the bridging retains are released.
        CFRelease(serviceRef)
        CFRelease(accountRef)
        return query
    }

    private fun ByteArray.toNSData(): NSData =
        usePinned { pinned ->
            NSData.create(bytes = pinned.addressOf(0), length = size.convert())
        }

    private fun NSData.toByteArray(): ByteArray {
        val size = length.toInt()
        val out = ByteArray(size)
        if (size > 0) {
            out.usePinned { pinned ->
                memcpy(pinned.addressOf(0), bytes, length)
            }
        }
        return out
    }

    private companion object {
        const val DEFAULT_SERVICE: String = "org.privacyperiod.database-key"
        const val DEFAULT_ACCOUNT: String = "primary"
    }
}
