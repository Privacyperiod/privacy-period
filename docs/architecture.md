<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
<!-- Copyright (C) 2026 Privacy Period Contributors -->

# Architecture

System design and data flow for Privacy Period. For the non-negotiable
constraints behind these choices see `CLAUDE.md`; for the privacy guarantees see
`docs/privacy-model.md`; for encryption specifics see `docs/encryption.md`.

## Overview

Privacy Period is a **Kotlin Multiplatform (KMP)** app. All domain logic — the
data layer, clinical scoring, encryption keying — lives in the shared module and
is covered by tests. Each platform supplies a thin, native UI:

- **iOS (MVP):** SwiftUI, consuming the shared module as an `Shared` framework.
- **Android (later):** Jetpack Compose, consuming the same shared module.

Three properties shape every layer: it runs **fully offline** (no feature makes a
network call), all persisted data is **encrypted at rest**, and clinical output is
**never a diagnosis** — only a factual summary to share with a clinician.

```
┌───────────────────────────┐      ┌───────────────────────────┐
│  iOS — SwiftUI             │      │  Android — Compose (later) │
│  Features / DesignSystem   │      │                            │
│  Data/EncryptedStore  ─────┼──┐   └───────────────────────────┘
└───────────────────────────┘  │
                                ▼
        ┌───────────────────────────────────────────────┐
        │  shared (KMP)                                   │
        │  clinical · pmdd · pme · crypto · data.db       │
        │  ClinicalRepository / ClinicalModule / scoring  │
        └───────────────────────────────────────────────┘
                                │
                                ▼
        ┌───────────────────────────────────────────────┐
        │  SQLDelight + SQLCipher (encrypted SQLite)      │
        │  key from KeyStorage → iOS Keychain             │
        └───────────────────────────────────────────────┘
```

## Shared module (`shared/`)

| Package | Responsibility |
|---|---|
| `data.db` | SQLDelight schema (`*.sq`) + the platform driver factory |
| `clinical` | The universal data layer: models, repository, module interface |
| `crypto` | `KeyStorage` (the database key) and `CryptoProvider` |
| `pmdd` | DRSP catalog + dictionary, C-PASS scorer, PMDD module, PMDD-vs-PME classifier, `PmddFeature` |
| `pme` | MAC-PMSS catalog, PME module, `PmeFeature` |
| `shared` | `PrivacyPeriodBridge` — small Swift/Kotlin interop helpers |

## The universal data layer

Clinical modules are **manifests, not storage.** Everything loggable flows
through one substrate so a symptom logged once serves every module that needs it.

- **`symptom_definitions`** — the catalogue. Stable string id (`drsp_1`,
  `macpmss_low_energy`), `category`, `severity_scale`, and the provenance pair
  (`clinical_provenance` + `provenance_item`) that ties each clinical item to its
  validated instrument. User-defined items use `clinical_provenance = 'custom'`.
- **`symptom_entries`** — one row = one symptom rated on one day. UUID primary key
  (so a future encrypted backup merges across devices without collision);
  `severity` interpreted per the symptom's scale; **cycle context
  (`cycle_phase`, `cycle_day`) fixed at write time** and never recomputed on read,
  so correcting a past cycle's start date can't corrupt historical analysis;
  `same_day_logged` separates real-time from backdated entries. One rating per
  symptom per day (unique index).
- **Sibling tables** carry the rest on the same encrypted database:
  `cycle_entries`, `flow_events`, `measurement_entries`, `mood_entries`
  (non-clinical daily wellbeing, excluded from module scoring), `medications`,
  `birth_control_entries`, `event_entries`, `module_enrollments`,
  `instrument_completions`, `app_settings`.

SQLite dialect note: the schema targets SQLite 3.18 (no `UPSERT`); writes use
`INSERT OR REPLACE` or an explicit `UPDATE`.

## The clinical module abstraction

```
ClinicalModule  ── runScoring(history) ─▶ ScoringResult
      ▲                                        │
      │ requiredSymptoms / checkReadiness      │
      │                                        ▼
ClinicalRepository ──▶ ClinicalHistory  (read-only snapshot for scoring)
      │
      └── saveSymptomEntry / seedCatalog / enroll / enrollment
```

- **`ClinicalModule`** (interface): a module declares the `symptom_definitions` it
  needs (`requiredSymptoms`), whether same-day logging is enforced, its minimum
  cycles, a `checkReadiness`, and `runScoring`. Implementations: `PmddModule`,
  `PmeModule`.
- **`ClinicalRepository`**: the single read/write gateway. Seeds the catalog,
  writes symptom entries, records module enrollments, and produces a
  `ClinicalHistory`. Modules never touch the database directly.
- **`ClinicalHistory`**: a read-only, lazily-cached snapshot a module scores over.
- Adding a module = a catalog manifest + a scorer + a UI flow + a report
  generator. **No new storage tables.**

## Clinical scoring

- **PMDD — C-PASS** (`pmdd/CpassScorer.kt`): a clean-room Kotlin reimplementation
  of the Carolina Premenstrual Assessment Scoring System over the DRSP entries.
  Item → domain → cycle → subject. Conformance-proven identical to the `lasy/cpass`
  reference (37/37 cycles, 20/20 subjects; `docs/cpass-conformance.md`).
- **PMDD-vs-PME differentiation** (`pmdd/PmddVsPmePatternClassifier.kt`): compares
  the follicular-phase mean against the luteal-phase mean for the differentiating
  items. PMDD = low follicular baseline that rises; PME = already-elevated baseline
  that rises further. Produces a factual *pattern*, never a diagnosis.
- **Provenance + gating:** every clinical item ties out to its instrument in
  `docs/clinical-provenance.md`. Validated instruments (DRSP, MAC-PMSS) are
  licensed; their wording is **not** in this repo (referenced by number with
  paraphrase labels; official text loads from a separately-licensed asset). Each
  module is hidden behind a feature flag (`PmddFeature`, `PmeFeature`, both off)
  until clinical/safety sign-off (`docs/clinical-disclaimer.md`).

## Encryption

- **Key:** `KeyStorage` generates a 256-bit key on first use and holds it in the
  **iOS Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`); it never
  leaves the device and is never logged. `clearDatabaseKey()` backs the
  irreversible "delete all data" action.
- **Database:** `DatabaseDriverFactory.createEncryptedDatabase()` opens the
  SQLDelight database through **SQLCipher** — AES-256-CBC with HMAC-SHA-512 (an
  authenticated cipher; *not* GCM), page key derived via PBKDF2-HMAC-SHA-512. The
  key is supplied as SQLCipher's `key` PRAGMA before any other access.
- **Graceful degrade:** key/DB open is declared throwing so the iOS layer can catch
  and run read-only-unavailable (e.g. an unsigned simulator build where the
  Keychain returns `errSecMissingEntitlement`) rather than crash.

## iOS layer (`iosApp/PrivacyPeriod/`)

| Group | Contents |
|---|---|
| `App` | `PrivacyPeriodApp`, `RootView`, `AppState` |
| `DesignSystem` | The "Desert Dusk" kit — tokens, `DDLikert`, nav/form components, icons |
| `Data` | `EncryptedStore` — the bridge from views to `ClinicalRepository` |
| `Features` | `Onboarding`, `CycleLog`, `Dashboard`, and the gated `Pmdd`/PME screens |

- **`EncryptedStore`** owns the `PrivacyPeriodDatabase` + `ClinicalRepository`,
  seeds the catalog on launch (degrading on failure), and exposes typed calls
  (`save`, `saveCheckIn`, `savePmeCheckIn`, `cpassResult`, `pmePattern`,
  `enrollPme`). Views never query the database directly.
- **Interop:** Kotlin `object` → `X.shared`; `@Throws` → Swift `throws`; Kotlin
  enums compared with `==`; new Swift files require `xcodegen generate`.

## Cross-cutting rules

- **Localization:** zero hardcoded UI strings; all keys live in
  `Localizable.xcstrings` (iOS) / `strings.xml` (Android), resolved with
  `Locale`-aware formatters.
- **No network:** there is no networking layer. The only egress is an explicit,
  user-initiated clinician export (a share sheet) or opt-in encrypted backup.
- **Tooling/CI:** ktlint + detekt (Kotlin), SwiftLint `--strict` (Swift), KMP unit
  tests in `commonTest`, C-PASS conformance in `jvmTest`.

## Build topology

- `shared` builds for JVM (tests), iOS (framework), and later Android.
- iOS is an XcodeGen-generated project in a CocoaPods workspace; SQLCipher is
  linked into the iOS build. After editing `project.yml` or adding Swift files,
  run `xcodegen generate` then `pod install`.
