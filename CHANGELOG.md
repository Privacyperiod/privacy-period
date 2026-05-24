# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Repository bootstrap: project plan, agentic-instructions, AGPL-3.0 license,
  README, contributing guide, code of conduct, security policy, and issue/PR
  templates.
- Kotlin Multiplatform shared module with the initial SQLDelight schema
  (`cycle_entries`, `mood_entries`, `symptom_entries`, `symptom_definitions`,
  `birth_control_entries`, `app_settings`), pinned dependency versions via a
  Gradle version catalog, ktlint and Detekt static analysis, and cross-platform
  schema tests covering creation and round-trip persistence.
- iOS app scaffold: a SwiftUI `PrivacyPeriod` app (bundle id `org.privacyperiod.app`,
  iOS 16+) generated with XcodeGen and consuming the Kotlin Multiplatform `shared`
  module via CocoaPods. Includes SwiftLint, a `Localizable.xcstrings` string
  catalog, a DocC catalog, and an iOS CI workflow.
- On-device encryption: a `KeyStorage` abstraction with a Keychain-backed
  implementation (256-bit key, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`,
  never exported), a `CryptoProvider` contract for future encrypted backups, and
  an encrypted SQLDelight database driver. Documented in `docs/encryption.md`.
- First-run onboarding (iOS): a "Desert Dusk" welcome screen — a sun-and-mountains
  hero, the brand name and logo, a plain-language description, and an info pill —
  followed by an optional app-lock step, plus a placeholder dashboard. Completion
  is remembered so onboarding shows only once. Introduces the Desert Dusk design
  system in the app: colour and type tokens, the Instrument Serif / Outfit / IBM
  Plex Mono fonts, Lucide icons, and the app icon.
- Cycle logging (iOS): a "Log period" form (start date, optional end date, flow
  intensity, and an optional note) reached from the dashboard. Saving writes an
  encrypted `cycle_entries` row through `EncryptedStore`, which opens the
  SQLCipher database lazily and degrades gracefully — without crashing — if the
  Keychain is unavailable. A random, device-local identifier is generated inside
  the encrypted store on first open and never leaves the device. Adds reusable
  Desert Dusk form components (navigation bar, segmented control, field
  container).
- PMDD scoring engine (shared module, not yet user-facing): a clean-room Kotlin
  implementation of the Carolina Premenstrual Assessment Scoring System (C-PASS)
  for premenstrual-symptom screening, written from the published specification.
  Includes the DRSP item / DSM-5 domain dictionary and item-, domain-, cycle-,
  and subject-level scoring. A conformance suite proves the output is identical
  to the reference R package `lasy/cpass` on its example dataset (37 cycles, 20
  subjects); the results are published in `docs/cpass-conformance.md`. The
  feature is intentionally gated out of shipped builds until the clinical
  disclaimer in `docs/clinical-disclaimer.md` is reviewed and signed, and it
  never renders a diagnosis.
- Universal clinical data layer: a single encrypted substrate (`symptom_definitions`
  / `symptom_entries` with stable ids, UUID entries, write-time cycle context, and
  one rating per symptom per day; plus event, measurement, flow, medication,
  instrument-completion, and module-enrollment tables) that clinical modules
  consume through a `ClinicalRepository` / `ClinicalHistory`. Modules are manifests,
  not storage: a `ClinicalModule` declares the symptoms it needs and how to score
  them. Each clinical symptom ties out to a validated instrument via published
  provenance (`docs/clinical-provenance.md`).
- PMDD screening (iOS, gated): the same-day DRSP check-in, factual non-diagnostic
  summary, and clinician export now run on the universal layer — the check-in
  writes DRSP `symptom_entries`, and `PmddModule` scores them with the
  conformance-verified C-PASS scorer. Still hidden behind the `PmddFeature` gate
  until clinical sign-off.
- PME scoring engine (shared module, not yet user-facing): a second
  `ClinicalModule` (`PmeModule`) on the universal layer for premenstrual
  exacerbation. Adds the MAC-PMSS mood-chart items to the catalog (reusing the
  DRSP items) and a `PmddVsPmePatternClassifier` that distinguishes PMDD-like from
  PME patterns by the follicular baseline (the most clinically important
  distinction): low baseline rising premenstrually (PMDD) vs. an elevated baseline
  rising further (PME), plus ongoing-condition and no-pattern cases. Thresholds
  are the documented starting values pending clinical confirmation; the module is
  gated and never renders a diagnosis.

### Security

- The local database is encrypted at rest with SQLCipher (AES-256, authenticated);
  the key lives only in the iOS Keychain. Verified by tests covering an encrypted
  round-trip and that a wrong key cannot read the database.
