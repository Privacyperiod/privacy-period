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
- Heavy menstrual bleeding (iOS, gated): a flow-logging form (product, saturation,
  clots, flooding, or a measured-volume cup/disc reading) and a non-diagnostic
  per-cycle summary scored with the Pictorial Blood loss Assessment Chart (PBAC) on
  the universal layer. Behind the `HmbFeature` gate until clinical sign-off.
- Perimenopause (iOS, gated): the Greene Climacteric Scale — a 21-item questionnaire
  grouped by domain (anxiety, depression, somatic, vasomotor, sexual) with domain
  and total scores and a clinician-shareable summary. The scale is permission-free;
  its rating-scale key stays pinned at the top of the screen while the items scroll.
  Behind the `PeriFeature` gate.
- Endometriosis screening (iOS, gated): a short risk questionnaire scored with the
  published eClinicalMedicine (Chauvet et al., 2021) screening score, reported as a
  non-diagnostic risk band to share with a clinician, plus a gate scaffold for the
  separately-licensed EHP-30. Behind the `EndoFeature` gate.
- Daily mood & energy check-in (iOS): a quick once-a-day rating of overall mood and
  energy with an optional note — non-clinical wellbeing data, never part of clinical
  scoring. Both rate on the app's shared green→eggplant spectrum, oriented so the
  better end ("Great" / "High") reads green.
- Settings (iOS): the user's control over their own data — export a plain-text copy
  (share sheet) and permanently delete everything (with confirmation) — plus a
  privacy note and a link to the open-source repository on GitHub so the privacy and
  encryption claims can be audited.
- Dashboard (iOS): the real home screen — today's date, the current cycle day (from
  the latest logged period; factual, no prediction), today's mood check-in or a
  prompt to add it, the primary "Log period" action, and entry points to whichever
  clinical modules are revealed.
- Demo build configuration (iOS): a third Xcode build configuration ("Demo", a
  release build carrying a `DEMO` compilation flag) and matching scheme that reveal
  the gated clinical modules for TestFlight and clinician review through a single
  `ClinicalGate`, without un-gating the App Store ("Release") build. Each module
  still ships hidden behind its own feature flag until its own clinical sign-off.
- Conditions (iOS): a screen to choose which conditions you collect data on — which
  is what the home screen then surfaces (nothing clinical appears until you opt in).
  Selections persist through the universal `module_enrollments` layer. The premenstrual
  condition is a single choice with a follow-up that records whether you live with a
  diagnosed underlying condition, selecting DRSP-only (PMDD) or DRSP + the MAC-PMSS
  mood chart (PME). Copy is non-diagnostic, and the selectable list is bounded by the
  clinical sign-off gate — the App Store build lists only signed-off conditions, the
  Demo build lists all. First step of the landing-page / navigation redesign.
- Soft mood & energy gate (iOS): the app opens onto the mood & energy check-in on each
  launch, setting the expectation that logging is the first thing you do. It is
  skippable after the first run ("Not today", recorded as a neutral non-entry — never a
  failure) and required only on the very first run; if today is already logged it is
  skipped automatically.
- Daily premenstrual log promoted (iOS): the premenstrual daily check-in (the PME mood
  & symptom check-in, or the DRSP check-in) is now a prominent top-level action
  alongside "Log period". The Conditions follow-up for an existing diagnosis is now
  multi-select (comorbidity is common), and "Choose conditions" reads "Choose conditions
  to track".
- Sample data (iOS, demo only): a Settings action that loads two cycles of sample DRSP
  entries so the pattern tracker can be previewed for testing and clinician review.
  Compiled into demo builds only, never the App Store build.
- Home organised into sections (iOS): the clinical entries are grouped into a
  collapsible **Tracking** section (the ongoing logs and result views, each
  cadence-tagged) and a **Screening** section (one-off questionnaires like
  endometriosis), with "Choose conditions to track" beneath. The daily premenstrual
  log and "Log period" remain prominent top-level actions.

### Security

- The local database is encrypted at rest with SQLCipher (AES-256, authenticated);
  the key lives only in the iOS Keychain. Verified by tests covering an encrypted
  round-trip and that a wrong key cannot read the database.
