# Encryption

This document describes how Privacy Period protects data at rest and what that
protection does — and does not — defend against. It is part of the privacy
promise: the code is the privacy policy, so the security model is written down and
reviewable.

## Summary

- All user data is stored in a local SQLite database that is **encrypted at rest**
  using **AES-256 with authenticated encryption** (see "Cipher" below).
- The encryption key is a **256-bit key generated on the device on first launch**.
  It is held only in the platform secure store — the **iOS Keychain** (and, later,
  the Android Keystore) — and **never leaves the device**, is never exported, and
  is never written to logs, preferences, or backups.
- There is **no server**. No key, and no user data, is ever transmitted off the
  device for the app's core features.

## Key lifecycle

1. **Generation.** On first launch, a cryptographically random 256-bit key is
   generated using the platform secure random source.
2. **Storage.** The key is stored via [`KeyStorage`](../shared/src/commonMain/kotlin/org/privacyperiod/crypto/KeyStorage.kt).
   The iOS implementation (`KeychainKeyStorage`) writes it to the Keychain with
   the accessibility attribute **`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`**:
   - *AfterFirstUnlock* lets the app open its database in the background (for
     example, to schedule a local notification) once the user has unlocked the
     device at least once since boot.
   - *ThisDeviceOnly* keeps the key out of iCloud Keychain and device backups, so
     it cannot follow the data to another device or into a backup.
3. **Use.** The raw key is read only to open the encrypted database driver. It is
   never copied, persisted elsewhere, or logged.
4. **Destruction.** "Delete all data" clears the key (`clearDatabaseKey`). Once the
   key is gone, the encrypted database file is permanently unrecoverable.

## Cipher

The mandated standard is **AES-256 authenticated encryption** (confidentiality
plus integrity). Two distinct mechanisms apply it:

- **Database at rest:** handled transparently by the encrypted database driver
  (SQLCipher). SQLCipher 4 encrypts pages with **AES-256-CBC** and authenticates
  them with **HMAC-SHA-512** (encrypt-then-MAC), deriving the page key from the
  stored key via PBKDF2-HMAC-SHA-512. This is the industry-standard construction
  for encrypted SQLite. (The exact integration approach is being finalised; see
  the project's integration plan.)
- **Backups and exports (later milestone):** the
  [`CryptoProvider`](../shared/src/commonMain/kotlin/org/privacyperiod/crypto/CryptoProvider.kt)
  contract encrypts data that intentionally leaves the app at the user's request.
  Its implementations use AES-256 authenticated encryption (on iOS, AES-GCM via
  CryptoKit on the Swift side). Nothing is ever transmitted without an explicit
  user action, and it is encrypted before it leaves the app.

## Threat model

**Protects against:**

- **Lost or stolen device.** Without the device unlocked (and without the
  Keychain key, which never leaves the secure store), the database file is
  ciphertext.
- **File-system / backup access.** Reading the raw database file — from a backup,
  another app's data sandbox escape, or offline disk inspection — yields only
  ciphertext. The key is not in the file, in preferences, or in backups.
- **Tampering.** Authenticated encryption causes decryption to fail rather than
  return forged or corrupted data.

**Does not protect against:**

- **A compromised running process** on an unlocked device (e.g. a jailbroken
  device with the app open, or OS-level malware). Once the app has legitimately
  opened the database, the data is in memory by design.
- **The device owner with the device unlocked.** App-lock (Face ID / Touch ID /
  PIN) is a separate, additive layer added in a later milestone.
- **A backdoored OS or hardware.** The platform secure store is trusted.

## Rules for contributors

- Never store the key anywhere but the platform secure store. No `UserDefaults`,
  no `SharedPreferences`, no files, no logs.
- Never log, print, or include key material in error messages or analytics (there
  are no analytics).
- Treat any change to this model as security-relevant: update this document in the
  same change, and flag it for review.
