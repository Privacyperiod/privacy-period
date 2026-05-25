# Agentic Instructions — Privacy Period

This file is the single master governing document for how AI coding agents assist
with the Privacy Period project. `CLAUDE.md` `@`-includes it; there is no other
authoritative version. Read this file fully before taking any action in this
repository. Any change to core architecture, the privacy model, or development
standards must be reflected here.

-----

## Project Identity

**Privacy Period** is a free, open source, privacy-first women's health tracking
app for iOS (MVP) and Android (later). It is a personal project, independent of
any employer or commercial entity.

- **License:** AGPL v3 — all code generated or modified must be compatible
- **Repository:** Public on GitHub from day one
- **Distribution:** Apple App Store (iOS), Google Play Store (Android)
- **Stack:** Kotlin Multiplatform (KMP) shared logic, SwiftUI (iOS), Jetpack Compose (Android)
- **Package / bundle root:** `org.privacyperiod` (never `dev.*` or any placeholder)

-----

## Current Project State

- **Foundation complete.** Repo, KMP shared module, iOS app (XcodeGen + CocoaPods
  workspace), and the encryption foundation are in place. The on-device database
  is encrypted with SQLCipher.
- **Universal data layer is built and in use.** Clinical data flows through one
  substrate (`symptom_definitions` + `symptom_entries`, with sibling tables for
  cycles, flow, measurements, etc.). The earlier "data-layer rebuild" is done.
- **PMDD module is built, re-homed onto the universal layer, and gated.** The
  C-PASS scoring engine is a clean-room Kotlin reimplementation, conformance-proven
  identical to the `lasy/cpass` reference (37/37 cycles, 20/20 subjects;
  `docs/cpass-conformance.md`). It stays behind `PmddFeature` (off) until
  `docs/clinical-disclaimer.md` is signed.
- **PME module is built and gated.** It tracks the MAC-PMSS (DRSP items + a mood
  chart) and runs the PMDD-vs-PME differentiation; behind `PmeFeature` (off)
  pending clinical + safety sign-off. The mood-chart items are placeholders until
  the MAC-PMSS instrument is licensed (see Principle 7).
- **Next:** finish the gated PME UI, then the backlog modules (Heavy Menstrual
  Bleeding, Perimenopause, Endometriosis, Fertility Awareness) — each on the
  universal layer, each gated until its own sign-off.

-----

## Non-Negotiable Principles

These are hard constraints, not guidelines. Every decision — architectural,
implementation, dependency — must satisfy all of them.

### 1. Universal Data Layer Substrate

- **All clinical data flows through one universal data layer** — symptoms, events,
  measurements, flow events, instrument completions.
- **Clinical modules do not own storage.** A module (PMDD, PME, HMB, Endometriosis,
  Perimenopause) is a manifest of the symptoms it cares about, a scoring algorithm,
  a UI flow, and a report generator. It has no database tables of its own.
- **A symptom is stored once and consumed by every module that needs it.** If a
  user enrolled in both PMDD and Perimenopause logs "depressed mood," that is one
  `symptom_entries` row, not two.
- **Cycle context is fixed at write time** (`cycle_phase`, `cycle_day`) and never
  recomputed on read — correcting a past cycle's start date must not retroactively
  rewrite the phase of historical entries.
- **Validated instruments are not modified.** DRSP, MAC-PMSS, EHP-30, Peri-SS, and
  the Greene Climacteric Scale items map to `symptom_definitions` rows. Adding
  user-defined symptoms (`clinical_provenance = 'custom'`) is fine; mixing them
  into a validated instrument is not.
- **Every clinical symptom ties out to established science** via
  `clinical_provenance` + `provenance_item`. The mapping is published in
  `docs/clinical-provenance.md`; each module adds a conformance report.

### 2. Privacy by Default

- **No analytics SDKs.** No Firebase Analytics, Mixpanel, Amplitude, Segment, or
  equivalent. Future telemetry, if ever, must be explicitly approved and self-hosted.
- **No crash reporting SDKs that phone home.** No Crashlytics, Sentry, or Datadog
  unless explicitly instructed and architected for zero PII transmission.
- **No advertising SDKs.** Ever. Not even as a placeholder.
- **No third-party SDKs that make network calls** without explicit approval.
  Before adding any dependency, state what network calls it makes, if any.
- **All user data stays on device** unless the user explicitly initiates an export
  or encrypted backup. No data is transmitted silently.

### 3. Zero-Knowledge Architecture

- The app must function fully offline. No feature may require a network call.
- No user account, email, or phone number is required or collected.
- The only identity is a locally generated UUID that never leaves the device.
- Encrypted backup is opt-in and encrypted on-device before any data moves.

### 4. Encryption is Mandatory

- All persisted user data must be encrypted at rest using AES-256 authenticated
  encryption. (The implementation is SQLCipher: AES-256-CBC plus HMAC-SHA-512 —
  **not** GCM. Do not describe it as "AES-256-GCM" anywhere.)
- Encryption keys must be stored in iOS Keychain / Android Keystore with
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or equivalent.
- Never store encryption keys in UserDefaults, SharedPreferences, plain files, or
  any location outside the platform secure-enclave APIs.
- Never log, print, or expose key material in any form.
- Never suppress, swallow, or silently ignore errors in security-critical paths.

### 5. Open Source Integrity

- All code is AGPL v3. Before adding a dependency, state its license. Acceptable:
  MIT, Apache 2.0, LGPL, MPL 2.0, AGPL. Incompatible: GPL-only libraries used in a
  way that conflicts with App Store distribution; proprietary SDKs.
- Do not add code that undermines the privacy guarantees in `docs/privacy-model.md`
  or the README.
- Code must be readable and auditable by the open source community. Prefer clarity
  over cleverness.

### 6. No Medical Claims

- The app is not a medical device and must not present itself as one.
- Do not generate UI strings, error messages, insight text, or documentation that
  diagnoses, prescribes, or makes clinical recommendations.
- Factual summaries of the user's own data are acceptable ("Your average cycle is
  28 days"). Interpretive or prescriptive claims are not ("You may have PMDD").
- Module output is always non-diagnostic: "Your tracked symptoms show a pattern
  consistent with [criteria]. Share this with a clinician." Never assert a diagnosis.
- Clinical modules (PMDD, PME, Endometriosis, …) require clinical-reviewer sign-off
  on every user-facing string before shipping, and stay gated until then.
- **Suicidal-ideation / self-harm items** are never a blocking popup, never
  transmit data, and never contact emergency services; they offer "prefer not to
  answer" (which counts as answered) and surface support resources gently. They
  ship only after specialist safety review.

### 7. Clinical Instrument Licensing

- The validated instruments are **licensed content**, and this repo is **public
  AGPL** — so instrument wording must never be committed to the repo or relicensed
  under AGPL.
  - **DRSP** (Endicott et al.) — item wording is licensed; the code references
    items by number and shows loose paraphrase labels only. `DrspDictionary.kt`
    deliberately stores no official wording.
  - **C-PASS** (Eisenlohr-Moul et al.) — method is published; our scorer is
    clean-room; the `lasy/cpass` reference is CC BY 4.0 → attribution only.
  - **MAC-PMSS** (Frey et al.; route via IAPMD) — not yet licensed; the PME
    mood-chart items in code are placeholders we authored and must be replaced
    verbatim with the licensed instrument before un-gating.
- **Never fabricate or paraphrase "official" clinical wording, definitions, or
  scale anchors.** Official text loads from a separately-licensed asset kept in the
  git-ignored clinical-materials folder; absent that asset the UI shows a neutral
  "available after licensing" state.
- Publish only the auditable outcomes (provenance + conformance), never the
  licensed instrument text. Licensing roadmap:
  `clinical condition screens and data/instrument-licensing.md` (local).

### 8. Fertility Awareness — Strict Language Rules

- The Fertility Awareness module (backlog) implements the Sensiplan symptothermal
  methodology as a tracking and self-awareness tool. It is **not** a contraceptive
  method and must never be presented as one. This keeps the app on the wellness
  side of the FDA general-wellness / Software-as-Medical-Device line.
- **Never generate any of these strings or equivalents:** "safe day," "low
  pregnancy risk," "not fertile today," "green day," "red day," "birth control,"
  "contraception," "effective for preventing pregnancy," or any effectiveness
  percentage; and never recommend sexual-behaviour changes from the output.
- Fertile-window display uses neutral language: "Your tracked signs indicate you
  are in your fertile window" / "Your fertile window has been confirmed closed for
  this cycle." Do not colour-code days red/green — users read that as a
  contraceptive signal regardless of disclaimers.
- The full spec and disclaimer text live in the local `module-fertility-awareness.md`;
  read it before working on this module. A regulatory review precedes shipping it.

### 9. Engagement & Adherence — No Gamification of Health

- Every feature touching adherence, reminders, progress, or motivation must comply
  with the standard in `user engagement/engagement-design.md` (local). It is
  grounded in Self-Determination Theory and self-monitoring-as-therapy: **the
  user's own emerging clinical picture is the only reward.**
- **Never build:** streak counters or "days in a row," points/coins/badges/
  trophies/levels, leaderboards or social comparison, variable-ratio (loot-box)
  reinforcement, progress bars that reset when "broken," unlockable themes/avatars,
  or external incentives. Our population (PMDD, depression, bipolar, anxiety,
  eating disorders) is specifically harmed by these patterns.
- **Never write shame or pressure language:** "you missed a day," "you broke your
  streak," "don't lose your progress," "catch up," disappointed tone, or generic
  praise ("Great job!"). Acknowledge difficulty honestly instead.
- The progress reveal is the user's **own cycle chart** filling in — not a separate
  game layer. Missing a day reduces completeness, never destroys progress.
- Reminders are **one per day at a user-chosen time** — no follow-ups, no
  escalation, no re-engagement nagging beyond a single gentle "your data is here
  when you're ready."
- Milestones are **clinical capabilities unlocking** (C-PASS validity days, a
  complete cycle, the 2-cycle analysis), stated factually. Validate engagement with
  the target population in TestFlight; clear the standard's open questions at
  clinical sign-off.

-----

## Attribution Rules

- **Do not label any code, comments, or documentation as co-developed by an AI,
  AI-generated, or AI-assisted.** Code and documentation should read as written by
  a single thoughtful human engineer.
- Do not add AI attribution in commit messages, docstrings, file headers,
  changelogs, PR descriptions, or anywhere else. **No `Co-Authored-By` and no
  "Generated with …" footer**, ever.
- Commits are authored as **`Privacy Period Contributors <joe@privacy-period.org>`**
  — never a personal account identity.

-----

## Code Quality Standards

### Documentation — Enforced, Not Optional

Every public function, class, object, interface, and module must have a
documentation comment. No exceptions.

**Kotlin (KMP shared module) — KDoc:**

```kotlin
/**
 * Calculates the predicted start date of the next menstrual cycle based on
 * historical cycle data.
 *
 * Uses a rolling average of the most recent [historyLimit] cycles. Returns
 * null if fewer than [MINIMUM_CYCLES_FOR_PREDICTION] complete cycles exist
 * in the provided history.
 *
 * @param history List of completed cycle entries, ordered oldest-first.
 * @param historyLimit Maximum number of recent cycles to include in the average.
 *   Defaults to [DEFAULT_HISTORY_LIMIT].
 * @return Predicted start date, or null if insufficient data.
 */
fun predictNextCycleStart(
    history: List<CycleEntry>,
    historyLimit: Int = DEFAULT_HISTORY_LIMIT
): LocalDate?
```

**Swift (iOS layer) — DocC:**

```swift
/// Presents the cycle logging interface for a given date.
///
/// If an entry already exists for `date`, the view opens in edit mode
/// with existing values pre-populated. New entries default to today's date.
///
/// - Parameters:
///   - date: The date for which to log or edit a cycle entry.
///   - animated: Whether to animate the presentation transition.
func presentCycleLog(for date: Date, animated: Bool = true)
```

**Inline comments:**

- Explain *why*, not *what*. The code shows what; the comment explains intent.
- Any non-obvious logic, security decision, or platform workaround must have an
  explanatory comment.
- Security-relevant code must have a comment explaining the security model.

### Code Style

**Kotlin:** ktlint defaults + Detekt rules; prefer immutability (`val`,
immutable collections); `sealed class` for domain results, not exceptions for
control flow; no force-unwrap (`!!`).

**Swift:** SwiftLint rules (CI runs `--strict`); prefer `let`; no force-unwrap
(`!`) except where provably safe and commented; `Result<Success, Failure>` for
fallible operations; no logic in View bodies.

**Both:** no magic numbers (named constants); no commented-out code on `main`; no
`TODO`/`FIXME` without a GitHub issue number — `// TODO(#42): …`.

### Testing Requirements

- All KMP domain logic has unit tests in `commonTest`.
- Cycle prediction: 100% unit coverage of edge cases (no data, one cycle, very
  irregular cycles, gaps).
- Encryption: round-trip tests (encrypt → decrypt → verify equality).
- Repositories: test with an in-memory SQLDelight driver.
- iOS UI: UI tests for critical paths (onboarding, log entry, export, delete-all).
- Tests must pass before any code is considered complete.

-----

## Commit and Branch Conventions

**Conventional Commits:** `type(scope): short description`. Types: `feat`, `fix`,
`docs`, `test`, `refactor`, `chore`, `security` (use for encryption changes),
`i18n`, `a11y`. Scopes (examples): `kmp`, `ios`, `android`, `crypto`, `db`,
`cycle`, `mood`, `symptoms`, `backup`, `settings`, `ci`.

**Branching:** `main` is always releasable, branch-protected, no direct pushes.
Work on `feat/…`, `fix/…`, `security/…` (may be private until patched), `docs/…`.

-----

## Internationalization (i18n) Rules

- **Zero hardcoded strings in any UI layer**, from the first screen.
- All user-facing strings go in `Localizable.xcstrings` (iOS) and `strings.xml`
  (Android). Key convention: `feature.component.description` in snake_case.
- Plurals use platform plural rules, not string concatenation.
- Date/time/number formatting uses `Locale`-aware system formatters. Never format
  dates manually.
- New UI screens always generate the string key + a placeholder English value.
  Never put the English string directly in the view.

-----

## Dependency Management

Before adding any dependency, state: (1) name + version, (2) license
(AGPL-compatible), (3) whether it makes network calls and what it sends, (4)
whether it is actively maintained, (5) whether a platform-API alternative exists.

Prefer platform APIs: `Swift Charts` over third-party charting; `CryptoKit` over
third-party crypto; `UNUserNotificationCenter` over any push SDK; `URLSession` if
networking is ever added.

-----

## Open Source Repository Requirements

- Every source file starts with the AGPL header:

```
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) [year] Privacy Period Contributors
```

- Public APIs documented before a PR is complete.
- New features get a `CHANGELOG.md` entry under `[Unreleased]`.
- Any change to the privacy model or encryption updates the relevant `docs/` file.
- Never commit secrets, API keys, device UUIDs, personal data, or licensed
  instrument text.

-----

## What the Agent Should Always Do

- **Read this file fully** before acting; **read the relevant module/spec doc**
  before implementing a clinical module.
- **State the plan before writing code** for any non-trivial task.
- **Prefer small, reviewable changes** — each logical unit a discrete commit.
- **Write tests alongside implementation.** Tests are part of done.
- **Flag security implications** immediately, even if not asked.
- **Ask before adding any dependency.** Never silently add a package.
- **Raise scope-creep concerns**, especially anything introducing tracking,
  network calls, or data collection.
- **For any new clinical module, declare which `symptom_definitions` it needs**
  before writing code; add missing ones to the catalog — never module storage.

## What the Agent Should Never Do

- **Create module-specific storage tables** for clinical data (`pme_entries`,
  `endometriosis_entries`, …). Clinical data lives in the universal layer.
- **Duplicate symptom definitions** across instruments (one "depressed mood" row).
- **Modify the items of a validated instrument**, or **fabricate/paraphrase
  official instrument wording, definitions, or anchors** (Principle 7).
- **Bypass the `ClinicalModule` abstraction from the iOS layer** (no direct DB
  queries from SwiftUI views).
- Add any SDK that collects data, phones home, or enables analytics.
- Store encryption keys outside Keychain / Keystore.
- Write UI strings directly in view code (i18n violation).
- Generate public APIs without documentation comments.
- Make medical or diagnostic claims in any user-facing string.
- Label code as AI-generated/assisted, or add AI attribution to commits/PRs.
- Commit directly to `main`.
- Add a dependency without stating its license and network behavior.
- Suppress, swallow, or silently ignore errors in security-critical paths.
- Drop or corrupt user data during any migration — existing entries must survive
  intact and produce identical scores.
- Scaffold or un-gate a clinical / mental-health module without explicit
  instruction and the relevant sign-off.

-----

## Reference Documents

### Published (in the repo)

| Document | Purpose |
|---|---|
| `privacy-period-project-plan.md` | Phased project plan, milestones, tech stack |
| `docs/architecture.md` | System design and data flow |
| `docs/privacy-model.md` | Detailed privacy guarantees *(to be created)* |
| `docs/encryption.md` | Encryption implementation details |
| `docs/clinical-provenance.md` | Instrument → item provenance registry (auditable) |
| `docs/cpass-conformance.md` | C-PASS conformance report vs `lasy/cpass` |
| `docs/clinical-disclaimer.md` | The gating sign-off for clinical modules |
| `docs/app_descriptions.md` | Approved App Store / GitHub / marketing copy |
| `CONTRIBUTING.md`, `CHANGELOG.md` | Contributor guide; Keep-a-Changelog history |

### Local working references (git-ignored; not published)

The internal planning material stays local; only the auditable outcomes above are
published. Folders: `clinical condition screens and data/`, `fertility awareness/`,
`user engagement/`, `design system/`.

| Document | Purpose |
|---|---|
| `clinical condition screens and data/clinical-screening-plan.md` | Universal-layer plan + module roadmap (backlog) |
| `clinical condition screens and data/conditions-and-instruments.md` | Condition catalog + validated instruments |
| `clinical condition screens and data/module-plans-and-overlap.md` | Per-module specs + PMDD-vs-PME differentiation |
| `clinical condition screens and data/instrument-licensing.md` | Instrument licensing roadmap (Principle 7) |
| `clinical condition screens and data/data-collection-design.md` | Data-collection design: scales, fields, scoring |
| `fertility awareness/module-fertility-awareness.md` | Sensiplan module spec + hard UI language rules |
| `user engagement/engagement-design.md` | Engagement/adherence standard (Principle 9) |

-----

*This file is the single source of truth. Earlier drafts (CLAUDEv2/v3/v4) are
superseded and removed; reconcile any future change into this file directly.*
