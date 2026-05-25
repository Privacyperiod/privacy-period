# Privacy Period

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)

A free, open source, **privacy-first menstrual and mental health** tracking app.
Track your cycle, mood, energy, and symptoms — with all of your data stored
**only on your device**, encrypted, and never shared.

> **Status:** Early development. iOS MVP in progress; Android to follow. The
> clinical screening modules described below are being built carefully and stay
> turned off until each has passed independent clinical and safety review.

## Why Privacy Period exists

Menstrual and mental health are deeply connected, and the conditions that sit at
that intersection — premenstrual dysphoric disorder, premenstrual exacerbation of
mood disorders, heavy menstrual bleeding, perimenopause, endometriosis — are
routinely under-recognised and can take **years** to diagnose.

A large part of why is structural: diagnosing them well requires consistent,
day-by-day, **prospective** tracking against validated clinical instruments —
exactly the kind of record almost no one keeps, and that a memory-based account at
a rushed appointment can't reconstruct.

Privacy Period exists to close that gap. It makes rigorous tracking effortless and
completely private, and turns it into a clear, **clinician-ready summary** you can
take to an appointment — so the conversation starts with real, structured data
instead of recall. **The app never diagnoses.** It does the tracking and the
arithmetic; you and your clinician do the rest.

## Conditions we're building for

Each screen below is built on a **validated, published instrument** and traces, in
public, to its source — see the [clinical provenance registry](docs/clinical-provenance.md).
Each produces a factual summary and an export to share with a clinician; **none
states a diagnosis**, and each stays gated until independent clinical (and, where
relevant, safety) review is complete.

| Focus | Tracked with | What it gives you |
|---|---|---|
| **PMDD** — premenstrual dysphoric disorder | DRSP daily diary, scored with C-PASS | A prospective two-cycle screening summary against the DSM-5 pattern |
| **PME** — premenstrual exacerbation of an existing mood disorder | MAC-PMSS + a PMDD-vs-PME pattern analysis | Whether symptoms *clear* after your period or *persist and worsen* — the distinction clinicians need |
| **Heavy menstrual bleeding** | PBAC (pictorial blood-loss assessment) | A per-cycle blood-loss estimate flagged against the clinical threshold |
| **Perimenopause** | Greene Climacteric Scale | A six-domain symptom-severity profile over time |
| **Endometriosis** | A validated symptom-questionnaire risk score (EHP-30 to follow) | A screening estimate of whether it's worth investigating |
| **Fertility awareness** *(backlog)* | Sensiplan symptothermal method | Body-literacy tracking — a wellness tool, **not** contraception |

This is the deeper purpose: private, validated, longitudinal data that helps these
under-served conditions get **seen** — and gets women to an accurate diagnosis
sooner.

## What it is

- A simple, fast period, mood, and symptom tracker.
- **Offline by design** — every feature works with no network connection.
- **Encrypted on device** — your data is stored with AES-256 authenticated
  encryption; the key never leaves your device's secure hardware (iOS Keychain /
  Android Keystore).
- **No account. No email. No phone number.** The only identity is a random ID
  generated on your device that never leaves it.
- **No analytics. No ads. No third-party tracking.** Ever.
- Backups and exports are **opt-in** and **encrypted before they leave the app** —
  nothing is transmitted unless you choose to.

## What it is not

- It is **not a medical device** and does not diagnose, prescribe, or give
  clinical advice. The clinical screens compare your own tracked data to published
  criteria and produce a factual summary to share with a clinician — the diagnosis
  is always the clinician's, made with you.

## Privacy guarantee

Your health data stays on your device. The app makes no network calls to deliver
its features. There is no server that holds your data, because there is no server
in the loop at all. The source is open so this can be independently verified —
**the code is the privacy policy.** See [`docs/encryption.md`](docs/encryption.md)
and the privacy and architecture notes in [`docs/`](docs/).

## Tech stack

- **Shared logic:** Kotlin Multiplatform (KMP) — data models, algorithms, database, encryption
- **iOS:** Swift / SwiftUI
- **Android (Phase 2):** Kotlin / Jetpack Compose
- **Database:** SQLDelight (encrypted at rest)
- **Encryption:** AES-256 authenticated encryption, keys in iOS Keychain / Android Keystore

System-design notes live in [`docs/`](docs/).

## Building from source

> Detailed, step-by-step build instructions land alongside the first app target.

In short, you will need Xcode (for iOS) and a JDK + Gradle (for the shared
module). See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development setup.

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
