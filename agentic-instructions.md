# Agentic Instructions — Privacy Period

This file governs how AI coding agents assist with the Privacy Period project.
Read this file fully before taking any action in this repository.

-----

## Project Identity

**Privacy Period** is a free, open source, privacy-first women’s health tracking
app for iOS (MVP) and Android (Phase 2). It is a personal project, independent
of any employer or commercial entity.

- **License:** AGPL v3 — all code generated or modified must be compatible
- **Repository:** Public on GitHub from day one
- **Distribution:** Apple App Store (iOS), Google Play Store (Android)
- **Stack:** Kotlin Multiplatform (KMP) shared logic, SwiftUI (iOS), Jetpack Compose (Android)
- **Reference:** See `privacy-period-project-plan.md` for full scope and phased milestones

-----

## Non-Negotiable Principles

These are hard constraints, not guidelines. Every decision — architectural,
implementation, dependency — must satisfy all of them.

### 1. Privacy by Default

- **No analytics SDKs.** Do not add Firebase Analytics, Mixpanel, Amplitude,
  Segment, or any equivalent. If telemetry is needed in future, it must be
  explicitly approved and self-hosted.
- **No crash reporting SDKs that phone home.** No Crashlytics, Sentry, or
  Datadog unless explicitly instructed and architected for zero PII transmission.
- **No advertising SDKs.** Ever. Not even as a placeholder.
- **No third-party SDKs that make network calls** without explicit approval.
  Before adding any dependency, state what network calls it makes, if any.
- **All user data stays on device** unless the user explicitly initiates an
  export or encrypted backup. No data is transmitted silently.

### 2. Zero-Knowledge Architecture

- The app must function fully offline. No feature may require a network call.
- No user account, email, or phone number is required or collected.
- The only identity is a locally generated UUID that never leaves the device.
- Encrypted backup is opt-in and encrypted on-device before any data moves.

### 3. Encryption is Mandatory

- All persisted user data must be encrypted at rest using AES-256-GCM.
- Encryption keys must be stored in iOS Keychain (iOS) or Android Keystore
  (Android) with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or equivalent.
- Never store encryption keys in UserDefaults, SharedPreferences, plain files,
  or any location outside the platform secure enclave APIs.
- Never log, print, or expose key material in any form.

### 4. Open Source Integrity

- All code is AGPL v3. Do not introduce dependencies with incompatible licenses.
  Before adding a dependency, state its license. Acceptable: MIT, Apache 2.0,
  LGPL, MPL 2.0, AGPL. Incompatible: GPL-only libraries used in a way that
  conflicts with App Store distribution, proprietary SDKs.
- Do not add any code that undermines the privacy guarantees stated in
  `docs/privacy-model.md` or the README.
- Code must be readable and auditable by the open source community. Prefer
  clarity over cleverness.

### 5. No Medical Claims

- The app is not a medical device and must not present itself as one.
- Do not generate UI strings, error messages, insight text, or documentation
  that diagnoses, prescribes, or makes clinical recommendations.
- Factual summaries of user’s own data are acceptable (“Your average cycle
  is 28 days”). Interpretive or prescriptive claims are not (“You may have PMDD”).
- The PMDD and mental health modules are out of scope until clinical review
  is complete. Do not scaffold, stub, or implement them without explicit instruction.

-----

## Attribution Rules

- **Do not label any code, comments, or documentation as AI-generated or
  AI-assisted.**
- Do not add AI attribution in commit messages, docstrings, file headers,
  changelogs, or anywhere else.
- Code and documentation should read as if written by a single thoughtful
  human engineer. This is the standard for the open source community.

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
- Any non-obvious logic, security decision, or platform workaround must have
  an explanatory comment.
- Security-relevant code must have a comment explaining the security model.

Example of a required security comment:

```swift
// Key is stored with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly to
// ensure it is available for background operations (e.g., notification
// processing) while preventing access when the device has never been unlocked
// after a reboot. This is the correct attribute for health data encryption keys.
```

### Code Style

**Kotlin:**

- Follow ktlint defaults (configured in `build.gradle.kts`)
- Follow Detekt rules (configured in `detekt.yml`)
- Prefer immutability: `val` over `var`, immutable collections by default
- Use `sealed class` for domain results, not exceptions for control flow
- No force-unwrap (`!!`) — handle nulls explicitly

**Swift:**

- Follow SwiftLint rules (configured in `.swiftlint.yml`)
- Prefer `let` over `var`
- No force-unwrap (`!`) except where provably safe and commented
- Use `Result<Success, Failure>` for operations that can fail
- ViewModels are `@Observable` or `ObservableObject` — no logic in View bodies

**Both:**

- No magic numbers — use named constants with explanatory names
- No commented-out code committed to `main`
- No `TODO` or `FIXME` committed without a corresponding GitHub issue number:
  `// TODO(#42): Handle irregular cycle edge case`

### Testing Requirements

- All KMP domain logic must have unit tests in `commonTest`
- Cycle prediction algorithm: 100% unit test coverage, covering edge cases
  (no data, one cycle, very irregular cycles, gaps in data)
- Encryption: round-trip tests (encrypt → decrypt → verify equality)
- Repositories: test with an in-memory SQLDelight driver
- iOS UI: UI tests for all critical paths (onboarding, log entry, export, delete-all)
- Tests must pass before any code is considered complete

-----

## Commit and Branch Conventions

### Commit Messages — Conventional Commits

Format: `type(scope): short description`

Types:

- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation only
- `test` — adding or correcting tests
- `refactor` — code change that is neither a fix nor a feature
- `chore` — build process, dependency updates, tooling
- `security` — security fix or hardening (use this for encryption-related changes)
- `i18n` — localization and translation changes
- `a11y` — accessibility improvements

Scopes (examples): `kmp`, `ios`, `android`, `crypto`, `db`, `cycle`, `mood`,
`symptoms`, `backup`, `settings`, `ci`

Examples:

```
feat(cycle): add cycle prediction algorithm with rolling average
security(crypto): use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly for key storage
fix(ios): correct date formatting for non-Gregorian calendars
docs(kmp): add KDoc to all CycleRepository public functions
i18n(ios): add French translations for onboarding screens
test(kmp): add edge case tests for irregular cycle prediction
```

### Branching

- `main` — always releasable, branch-protected, no direct pushes
- `feat/short-description` — feature branches
- `fix/short-description` — bug fix branches
- `security/short-description` — security fixes (may be kept private until patched)
- `docs/short-description` — documentation-only changes

-----

## Internationalization (i18n) Rules

- **Zero hardcoded strings in any UI layer.** This is enforced from the first screen.
- All user-facing strings go in `Localizable.xcstrings` (iOS) and `strings.xml` (Android).
- Key naming convention: `feature.component.description` in snake_case.
  Example: `onboarding.welcome.title`, `cycle_log.flow.heavy_label`
- Plurals must use platform plural rules, not string concatenation.
- Date, time, and number formatting must use `Locale`-aware system formatters.
  Never format dates manually.
- When generating new UI screens, always generate the string key and a
  placeholder English value. Never put the English string directly in the view.

-----

## Dependency Management

Before adding any dependency, the agent must state:

1. The dependency name and version
1. Its license (must be AGPL-compatible)
1. Whether it makes any network calls, and if so, what data it sends
1. Whether it is actively maintained (last commit, open issues)
1. Whether an alternative built on platform APIs exists

Prefer platform APIs over third-party libraries wherever reasonable:

- Prefer `Swift Charts` over third-party charting libraries
- Prefer `CryptoKit` (iOS) over third-party crypto libraries
- Prefer `UNUserNotificationCenter` over any push notification SDK
- Prefer `URLSession` if any networking is ever added

-----

## Open Source Repository Requirements

Every file added to the repository must be consistent with the open source
standards in `privacy-period-project-plan.md`. Specifically:

- All source files must have the AGPL v3 header comment at the top:

```
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) [year] Privacy Period Contributors
```

- Public APIs must be documented before a PR is considered complete
- New features need corresponding entries in `CHANGELOG.md` under `[Unreleased]`
- Any change to the privacy model or encryption implementation must update the
  relevant file in `docs/`
- Do not commit secrets, API keys, device UUIDs, or personal data of any kind

-----

## What the Agent Should Always Do

- **Read the project plan** (`privacy-period-project-plan.md`) before starting
  any new milestone to understand context and exit criteria.
- **State the plan before writing code.** For any non-trivial task, describe
  the approach first. This gives the opportunity to course-correct before
  implementation.
- **Prefer small, reviewable changes** over large monolithic implementations.
  Each logical unit of work should be a discrete, reviewable commit.
- **Write tests alongside implementation**, not after. Tests are part of done.
- **Flag security implications** of any architectural decision immediately,
  even if not asked.
- **Ask before adding any dependency.** Never silently add a package.
- **Raise concerns about scope creep** — particularly around features that
  could introduce user tracking, network calls, or data collection.

## What the Agent Should Never Do

- Add any SDK or library that collects data, phones home, or enables analytics
- Store encryption keys outside of Keychain / Keystore
- Write UI strings directly in view code (i18n violation)
- Generate code without documentation comments on public APIs
- Make medical or diagnostic claims in any user-facing string
- Label code as AI-generated or AI-assisted
- Commit directly to `main`
- Add a dependency without stating its license and network behavior
- Scaffold the PMDD or mental health modules without explicit instruction
- Suppress, swallow, or silently ignore errors in security-critical code paths

-----

## Reference Documents

|Document                        |Purpose                                                     |
|--------------------------------|------------------------------------------------------------|
|`privacy-period-project-plan.md`|Full project scope, phases, milestones, tech stack          |
|`docs/architecture.md`          |System design and data flow (to be created in Phase 1)      |
|`docs/privacy-model.md`         |Detailed privacy guarantees (to be created in Phase 1)      |
|`docs/encryption.md`            |Encryption implementation details (to be created in Phase 1)|
|`CONTRIBUTING.md`               |Contributor guide (to be created in Phase 1)                |
|`CHANGELOG.md`                  |Release history in Keep a Changelog format                  |

-----

*This file should be updated as the project evolves. Any change to core
architecture, privacy model, or development standards must be reflected here.*
