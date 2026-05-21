# Privacy Period

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

A free, open source, **privacy-first** women's health tracking app. Track your
menstrual cycle, mood, energy, symptoms, and birth control — with all of your
data stored **only on your device**, encrypted, and never shared.

> **Status:** Early development. iOS MVP in progress; Android to follow.

## What it is

- A simple, fast period, mood, and symptom tracker.
- **Offline by design** — every feature works with no network connection.
- **Encrypted on device** — your data is stored with AES-256-GCM; the key never
  leaves your device's secure hardware (iOS Keychain / Android Keystore).
- **No account. No email. No phone number.** The only identity is a random ID
  generated on your device that never leaves it.
- **No analytics. No ads. No third-party tracking.** Ever.
- Backups and exports are **opt-in** and **encrypted before they leave the app** —
  nothing is transmitted unless you choose to.

## What it is not

- It is **not a medical device** and does not diagnose, prescribe, or give
  clinical advice. It shows you factual summaries of your own data — nothing more.

## Privacy guarantee

Your health data stays on your device. The app makes no network calls to deliver
its features. There is no server that holds your data, because there is no server
in the loop at all. The source is open so this can be independently verified —
**the code is the privacy policy.** See the privacy and encryption notes in
[`docs/`](docs/) (added as the architecture lands).

## Tech stack

- **Shared logic:** Kotlin Multiplatform (KMP) — data models, algorithms, database, encryption
- **iOS:** Swift / SwiftUI
- **Android (Phase 2):** Kotlin / Jetpack Compose
- **Database:** SQLDelight (encrypted at rest)
- **Encryption:** AES-256-GCM, keys in iOS Keychain / Android Keystore

## Building from source

> Detailed, step-by-step build instructions land alongside the first app target.

In short, you will need Xcode (for iOS) and a JDK + Gradle (for the shared
module). The KMP `shared/` module is consumed by the iOS app via Swift Package
Manager. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development setup.

## App Store

> Link will be added when the iOS app is published.

## Contributing

Contributions are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) and
the [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) first. For anything security-related,
see [`SECURITY.md`](SECURITY.md) — please do **not** open public issues for
vulnerabilities.

## License

Privacy Period is licensed under the **GNU Affero General Public License v3.0**
(AGPL-3.0). See [`LICENSE`](LICENSE).
