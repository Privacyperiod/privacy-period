<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
<!-- Copyright (C) 2026 Privacy Period Contributors -->

# Privacy Model

The guarantees Privacy Period makes about your data, and how the architecture
enforces them. For the constraints behind these choices see `CLAUDE.md`; for the
system design see `docs/architecture.md`; for the cipher specifics see
`docs/encryption.md`.

## The promise

**Your data stays on your device, encrypted, and is never sent anywhere unless
you explicitly choose to share it.** There is no account, no tracking, and no
server that holds your information.

## Guarantees

### 1. No account, no identifiers collected

- The app requires no email, phone number, name, or sign-in.
- The only identity is a random UUID generated on-device on first run. It never
  leaves the device and is held only inside the encrypted database.
- We collect no advertising id, device fingerprint, or contact data.

### 2. Fully offline; nothing transmitted silently

- Every feature works with no network connection. There is no networking layer in
  the app to send data even if something tried to.
- The only ways data leaves the device are **explicit, user-initiated** actions:
  a clinician export (a share sheet you trigger) or an opt-in encrypted backup.
  Both are visible, deliberate, and never automatic.

### 3. Encrypted at rest

- All persisted data lives in a single SQLCipher database encrypted with AES-256
  authenticated encryption (AES-256-CBC + HMAC-SHA-512), keyed from a 256-bit key
  in the iOS Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- The key never leaves the secure enclave APIs, is never logged, and is never
  copied into preferences, plain files, or backups.
- See `docs/encryption.md` for the full scheme.

### 4. No analytics, ads, or third-party tracking

- No analytics SDKs (Firebase, Mixpanel, Amplitude, Segment, …).
- No advertising SDKs — ever.
- No crash-reporting SDKs that phone home (Crashlytics, Sentry, Datadog).
- No third-party SDK that makes a network call is added without explicit review;
  dependencies must state their license and network behaviour first.

### 5. You own and can erase your data

- **Export:** you can produce a clinician-ready report on demand; it is generated
  locally and shared only through the OS share sheet you invoke.
- **Delete all:** erasing the database key (Keychain) renders the encrypted
  database permanently unrecoverable — a true, irreversible delete, not a
  soft-delete or a server-side "request."
- **Backup:** any backup is opt-in and encrypted on-device *before* anything moves.

### 6. No diagnosis, no clinical content leaves the device

- Clinical modules (PMDD, PME, …) never state a diagnosis; they produce factual
  summaries to share with a clinician, and stay gated until clinical sign-off.
- Validated clinical instruments are **licensed**; their wording is not embedded in
  this public repository (referenced by number; official text loads from a
  separately-licensed asset). See `CLAUDE.md` Principle 7.

## What is on-device vs. published

| Category | Where it lives |
|---|---|
| All your logged data (cycles, symptoms, moods, measurements) | On-device only, in the encrypted database |
| The device UUID | On-device only, inside the encrypted database |
| The source code | Public (AGPL v3) on GitHub |
| Clinical provenance + conformance (how scoring ties to the science) | Public, in `docs/` — contains no user data and no licensed instrument text |

## Threat model (what this protects against)

- **A lost or stolen device:** data is encrypted at rest; the key is bound to the
  device's secure enclave and available only after first unlock.
- **A network observer or compromised server:** there is no server and no
  transmission, so there is nothing to intercept.
- **A curious third party / data broker:** no analytics, ads, or identifiers means
  there is no behavioural data to collect or sell.

### What it does not claim

- It does not defend against a fully compromised OS or a jailbroken device where
  the secure enclave and process memory are attacker-controlled.
- A user-initiated export or backup is the user's responsibility once it leaves the
  app; the app encrypts backups but cannot govern where you then store them.
- It is not a medical device and makes no clinical guarantees.

## How this is enforced in code

- No networking layer exists; adding one requires explicit review (`CLAUDE.md`).
- The encrypted database is the only persistence path; keys come solely from
  `KeyStorage` → Keychain (`docs/architecture.md`).
- CI (ktlint, detekt, SwiftLint) and code review guard against dependencies or
  patterns that would breach these guarantees. Any change here must update this
  document.
