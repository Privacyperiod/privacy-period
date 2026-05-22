# Contributing to Privacy Period

Thank you for your interest in contributing. Privacy Period is built around a
small set of non-negotiable principles — please read them before you start, then
follow the workflow below.

## Core principles (please respect these in every contribution)

- **Privacy by default.** No analytics, ads, crash-reporting-that-phones-home,
  or any SDK that makes network calls, without explicit prior discussion.
- **Offline-first / zero-knowledge.** Every feature must work fully offline.
  No accounts, no emails, no phone numbers. No data leaves the device unless the
  user explicitly exports or backs it up (and it is encrypted first).
- **Encryption is mandatory.** User data is encrypted at rest (AES-256 authenticated encryption);
  keys live only in the iOS Keychain / Android Keystore. Never log or expose keys.
- **No medical claims.** Factual summaries of the user's own data only — never
  diagnostic, prescriptive, or interpretive language.

If a change can't satisfy all of these, please open an issue to discuss before
writing code.

## Before you write code: open an issue

For anything beyond a trivial fix, **open an issue first** so the approach can be
discussed. This avoids wasted work. Bugs, features, and security concerns each
have an issue template.

## Development setup

- **iOS:** Xcode 16+, plus XcodeGen, SwiftLint, and CocoaPods
  (`brew install xcodegen swiftlint cocoapods`). The `.xcodeproj` and
  `.xcworkspace` are generated and git-ignored. From `iosApp/`:

  ```sh
  xcodegen generate
  ../gradlew :shared:podspec :shared:generateDummyFramework
  pod install
  ```

  then open/build `PrivacyPeriod.xcworkspace`. The app consumes the KMP `shared/`
  module as a CocoaPods pod, which builds the `Shared` framework via Gradle and
  links **SQLCipher** (used to encrypt the database at rest). Re-run the steps
  above after editing `project.yml` or the Gradle config.
- **Shared module:** a JDK 21 and the bundled Gradle wrapper (`./gradlew`). The
  `shared/` module holds all data models, algorithms, database queries, and
  encryption logic.

## Running tests

- **Shared (KMP):** `./gradlew :shared:allTests` (unit tests live in `commonTest`;
  they run on both the JVM and the iOS simulator).
- **iOS:** after the setup steps above, build/test the `PrivacyPeriod` scheme from
  `PrivacyPeriod.xcworkspace` in Xcode or with `xcodebuild -workspace`. The
  encrypted-database tests run as part of `:shared:iosSimulatorArm64Test`.

Tests must pass before a change is considered complete. New logic ships **with**
its tests, not after.

## Code style

- **Swift:** SwiftLint (config in `.swiftlint.yml`). Prefer `let`, avoid
  force-unwraps, keep logic out of View bodies.
- **Kotlin:** ktlint + Detekt (configured in Gradle). Prefer `val` and
  immutability, avoid `!!`, use `sealed class` results over exceptions for
  control flow.
- **Both:** named constants over magic numbers; no commented-out code on `main`;
  any `TODO`/`FIXME` must reference an issue number, e.g. `// TODO(#42): …`.

## Documentation is required

Every public function, class, object, interface, and module must have a
documentation comment — **KDoc** in Kotlin, **DocC** in Swift. Document
non-obvious parameters and any security or privacy implication. Prefer readable
code with intent-explaining comments over clever code.

## Internationalization

No hardcoded user-facing strings. All strings go in the platform string catalog
(`Localizable.xcstrings` on iOS, `strings.xml` on Android) using
`feature.component.description` snake_case keys. Use locale-aware formatters for
dates and numbers.

## Commit messages — Conventional Commits

Format: `type(scope): short description`

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `security`, `i18n`,
`a11y`. Example scopes: `kmp`, `ios`, `android`, `crypto`, `db`, `cycle`, `mood`,
`symptoms`, `backup`, `settings`, `ci`.

Examples:

```
feat(cycle): add cycle prediction algorithm with rolling average
security(crypto): store key with after-first-unlock-this-device-only protection
docs(kmp): add KDoc to all CycleRepository public functions
```

## Branching & pull requests

- `main` is protected — no direct pushes. Work on a branch:
  `feat/…`, `fix/…`, `security/…`, or `docs/…`.
- Open a PR against `main`. CI (lint, tests, build) must pass.
- Keep PRs small and focused — one logical change per PR.
- The PR template includes a checklist; please complete it.

## Source file headers

Every source file starts with the AGPL header:

```
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors
```

## License

By contributing, you agree that your contributions are licensed under the
AGPL-3.0, consistent with the rest of the project.
