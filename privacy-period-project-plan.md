# Privacy Period — Project Plan

**Version 1.0 | Personal Project**

-----

## Project Summary

**Privacy Period** is a free, open source women’s health tracking app for iOS (MVP) and Android (Phase 2). It tracks menstrual cycles, mood, symptoms, PMDD patterns, and birth control. All data is stored locally, encrypted on-device, and never shared with third parties. No account is required. No analytics. No ads. Ever.

**License:** AGPL v3  
**Repository:** GitHub (public from day one)  
**Distribution:** Apple App Store (iOS), Google Play Store (Android)  
**Builder:** Solo developer + Claude Code  
**Target MVP Launch:** iOS App Store, ~6–8 weeks from project start

-----

## Guiding Principles

These principles are not aspirational — they are constraints that govern every technical decision:

1. **Device-first.** All core functionality works fully offline.
1. **Zero-knowledge.** The app knows as little about the user as technically possible.
1. **No account required.** A local UUID generated on first launch is the only identity.
1. **No third-party SDKs that phone home.** Every dependency is audited.
1. **Open source as trust.** The code is the privacy policy.
1. **Internationalization from day one.** No strings hardcoded in UI.
1. **Well-documented, well-commented code.** Sustainable for community contribution.

-----

## Tech Stack

|Layer                |Technology                               |Notes                                                    |
|---------------------|-----------------------------------------|---------------------------------------------------------|
|Shared business logic|Kotlin Multiplatform (KMP)               |Data models, algorithms, DB queries, encryption utilities|
|iOS UI               |Swift / SwiftUI                          |Native feel, full platform integration                   |
|Android UI (Phase 2) |Kotlin / Jetpack Compose                 |Shares all KMP logic                                     |
|Local database       |SQLDelight                               |KMP-compatible, type-safe SQL, shared schema             |
|Encryption           |AES-256-GCM                              |Key stored in iOS Keychain / Android Keystore            |
|Local backup         |Encrypted file export                    |User-initiated, encrypted before leaving the app         |
|Build system         |Gradle (KMP) + Xcode                     |Standard for this stack                                  |
|CI/CD                |GitHub Actions                           |Lint, test, build on every PR                            |
|Localization         |iOS: Localizable.strings + StringCatalogs|i18n scaffolded from first screen                        |
|Dependency management|Swift Package Manager (iOS), Gradle (KMP)|No CocoaPods                                             |
|Documentation        |KDoc (Kotlin), DocC (Swift)              |Enforced in code review / PR template                    |

-----

## Repository Structure

```
privacy-period/
├── .github/
│   ├── workflows/
│   │   ├── ios-ci.yml            # Build, lint, test on every PR
│   │   ├── android-ci.yml        # Phase 2
│   │   └── dependency-audit.yml  # Weekly dependency security scan
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── security_concern.md   # Redirects to SECURITY.md
│   └── PULL_REQUEST_TEMPLATE.md
│
├── docs/
│   ├── architecture.md           # System design, data flow diagrams
│   ├── privacy-model.md          # Detailed explanation of privacy guarantees
│   ├── encryption.md             # Encryption implementation details
│   ├── contributing-guide.md     # Extended contributor guide
│   ├── clinical-disclaimer.md    # Language reviewed by clinician (Phase 3)
│   └── roadmap.md                # Public-facing roadmap
│
├── shared/                       # KMP shared module
│   ├── src/
│   │   ├── commonMain/
│   │   │   ├── kotlin/
│   │   │   │   └── org/privacyperiod/
│   │   │   │       ├── data/
│   │   │   │       │   ├── model/         # CycleEntry, MoodEntry, SymptomEntry, etc.
│   │   │   │       │   ├── repository/    # Repository interfaces
│   │   │   │       │   └── db/            # SQLDelight schema files
│   │   │   │       ├── domain/
│   │   │   │       │   ├── cycle/         # Cycle prediction algorithms
│   │   │   │       │   ├── mood/          # Mood pattern analysis
│   │   │   │       │   └── insights/      # On-device insight generation
│   │   │   │       ├── crypto/            # Encryption utilities (platform-agnostic layer)
│   │   │   │       └── util/              # Date utilities, extensions
│   │   ├── iosMain/               # iOS-specific KMP implementations
│   │   │   └── kotlin/
│   │   │       └── org/privacyperiod/
│   │   │           ├── crypto/    # Keychain-backed key storage
│   │   │           └── db/        # iOS SQLDelight driver
│   │   ├── androidMain/           # Android-specific (Phase 2)
│   │   └── commonTest/            # Shared unit tests
│
├── iosApp/                        # SwiftUI iOS application
│   ├── PrivacyPeriod/
│   │   ├── App/
│   │   │   ├── PrivacyPeriodApp.swift
│   │   │   └── AppCoordinator.swift
│   │   ├── Features/
│   │   │   ├── Onboarding/
│   │   │   ├── Dashboard/
│   │   │   ├── CycleLog/
│   │   │   ├── MoodLog/
│   │   │   ├── Symptoms/
│   │   │   ├── Insights/
│   │   │   ├── Settings/
│   │   │   └── Backup/
│   │   ├── SharedUI/              # Reusable SwiftUI components
│   │   ├── Resources/
│   │   │   └── Localizable.xcstrings   # String catalog (i18n)
│   │   └── Preview Content/
│   └── PrivacyPeriodTests/
│
├── androidApp/                    # Phase 2 — placeholder only in MVP
│
├── LICENSE                        # AGPL v3
├── README.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md             # Contributor Covenant 2.1
├── SECURITY.md
└── CHANGELOG.md                   # Keep a Changelog format
```

-----

## Open Source Repository Standards

### Files Required at Launch (Day One)

**README.md** must include:

- What the app is and what it is not
- Privacy guarantee stated plainly
- How to build from source (iOS and, later, Android)
- Link to App Store listing
- License badge
- Contribution welcome statement

**CONTRIBUTING.md** must include:

- Code style guide (SwiftLint config, Kotlin linting via ktlint)
- How to run tests locally
- PR process and review expectations
- Commit message format (Conventional Commits)
- Documentation requirement: all public functions must have KDoc/DocC comments
- How to propose new features (issue first, code second)

**CODE_OF_CONDUCT.md**

- Use Contributor Covenant 2.1 verbatim
- Designate a contact email for violations (create a dedicated address)

**SECURITY.md**

- No public issue filing for security vulnerabilities
- Private disclosure process (GitHub private vulnerability reporting)
- Response commitment: acknowledge within 72 hours, patch timeline communicated

**CHANGELOG.md**

- Keep a Changelog format (keepachangelog.com)
- Entries: Added, Changed, Deprecated, Removed, Fixed, Security
- Updated with every release, no exceptions

### Code Standards Enforced via CI

- **SwiftLint** — iOS code style, enforced on every PR
- **ktlint** — Kotlin code style, enforced on every PR
- **Detekt** — Kotlin static analysis
- All PRs require passing CI before merge
- Branch protection on `main`: no direct pushes, PR required
- Semantic versioning (semver.org): `MAJOR.MINOR.PATCH`
- Git tags on every release

### Documentation Standard

Every public function, class, and module must have:

- **KDoc** comment in Kotlin (shared module)
- **DocC** comment in Swift (iOS layer)
- Parameter descriptions for non-obvious parameters
- A note on any security or privacy implication where relevant

No “clever” code without an explanatory comment. Prefer readable over terse.

-----

## Phase 1 — Foundation (Weeks 1–2)

**Goal:** Repository live, architecture proven, nothing ships to users yet.

### Milestone 1.1 — Repository Bootstrap

- [ ] Create GitHub repository: `privacy-period` (public)
- [ ] Write and commit `LICENSE` (AGPL v3)
- [ ] Write `README.md` with project philosophy, build instructions placeholder, App Store link placeholder
- [ ] Write `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`
- [ ] Create `CHANGELOG.md` with `[Unreleased]` section
- [ ] Create issue templates and PR template
- [ ] Configure branch protection on `main`
- [ ] Set up GitHub Discussions for community Q&A
- [ ] Create a dedicated contact email for the project (security, CoC violations)

### Milestone 1.2 — KMP Shared Module Setup

- [ ] Initialize Kotlin Multiplatform project with `iosMain` and `commonMain` targets
- [ ] Configure `build.gradle.kts` with dependency versions pinned
- [ ] Add SQLDelight plugin and configure for KMP
- [ ] Define initial database schema:
  - `cycle_entries` (id, start_date, end_date, flow_intensity, notes, created_at)
  - `mood_entries` (id, date, mood_score, energy_score, notes, created_at)
  - `symptom_entries` (id, date, symptom_id, severity, created_at)
  - `symptom_definitions` (id, name_key, category, is_custom)
  - `birth_control_entries` (id, type, taken_at, notes, created_at)
  - `app_settings` (key, value)
- [ ] Write KDoc comments for every schema table
- [ ] Write `commonTest` unit tests for schema migrations
- [ ] Set up ktlint and Detekt in Gradle

### Milestone 1.3 — iOS Project Setup

- [ ] Create Xcode project: `PrivacyPeriod`
- [ ] Configure Swift Package Manager — add KMP shared module as local package
- [ ] Configure SwiftLint with project ruleset (`.swiftlint.yml` committed to repo)
- [ ] Set up i18n infrastructure:
  - Create `Localizable.xcstrings` String Catalog
  - Establish key naming convention: `feature.component.description` (e.g., `onboarding.welcome.title`)
  - Add English as base language; scaffold structure for additional languages
- [ ] Set minimum iOS deployment target (iOS 16 recommended — SwiftUI maturity, broad device support)
- [ ] Configure app bundle ID: `org.privacyperiod.app`
- [ ] Set up DocC documentation target
- [ ] Add GitHub Actions workflow: `ios-ci.yml`
  - Triggers: push to `main`, all PRs
  - Steps: checkout, setup Xcode, resolve packages, build, run tests, SwiftLint

### Milestone 1.4 — Encryption Foundation

- [ ] Implement `CryptoProvider` interface in KMP `commonMain`
  - `generateKey(): ByteArray`
  - `encrypt(data: ByteArray, key: ByteArray): ByteArray`
  - `decrypt(data: ByteArray, key: ByteArray): ByteArray`
- [ ] Implement `KeychainKeyStorage` in `iosMain`
  - Stores AES-256 key in iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
  - Key generated on first launch, never exported
  - KDoc comment on every method explaining the security model
- [ ] Implement encrypted SQLDelight driver wrapper for iOS
- [ ] Write unit tests for encrypt/decrypt round-trip
- [ ] Document encryption model in `docs/encryption.md`

**Phase 1 Exit Criteria:** Repository is public, KMP module compiles, encrypted database reads and writes work in a test, CI passes.

-----

## Phase 2 — Core iOS Features (Weeks 3–4)

**Goal:** A working app on your own device. Not beautiful, but functional and correct.

### Milestone 2.1 — Onboarding Flow

- [ ] Welcome screen — privacy promise stated plainly, no dark patterns
- [ ] “No account needed” explanation screen
- [ ] Optional: set a PIN or Face ID / Touch ID lock
- [ ] Local UUID generation on first launch (stored encrypted, never transmitted)
- [ ] All strings in `Localizable.xcstrings`

### Milestone 2.2 — Cycle Logging

- [ ] Log period start
- [ ] Log period end
- [ ] Flow intensity selection (light / medium / heavy / spotting)
- [ ] Optional free-text note per entry
- [ ] Edit and delete past entries
- [ ] KMP domain layer: `CycleRepository` with full KDoc

### Milestone 2.3 — Mood & Energy Logging

- [ ] Daily mood check-in (emoji-based scale — avoids translation complexity)
- [ ] Energy level check-in
- [ ] Optional free-text note
- [ ] One entry per day, editable
- [ ] KMP domain layer: `MoodRepository` with full KDoc

### Milestone 2.4 — Symptom Tracking

- [ ] Predefined symptom library (cramps, headache, bloating, breast tenderness, acne, fatigue, insomnia, backache, nausea)
- [ ] User can add custom symptoms
- [ ] Severity scale per symptom (1–5)
- [ ] KMP domain layer: `SymptomRepository` with full KDoc
- [ ] All symptom display names use i18n keys

### Milestone 2.5 — Dashboard

- [ ] Current cycle day indicator
- [ ] Days since last period
- [ ] Quick-log shortcuts (log today’s mood, log symptom)
- [ ] Recent entries summary
- [ ] No network calls, no loading states for primary content

**Phase 2 Exit Criteria:** App installs on a physical device, core logging features work end-to-end, all data persists encrypted across app restarts.

-----

## Phase 3 — Cycle Intelligence & Insights (Week 5)

**Goal:** The app becomes useful, not just a log.

### Milestone 3.1 — Cycle Prediction Algorithm

- [ ] Implement in KMP `commonMain` — fully on-device
- [ ] Algorithm: rolling average of last N cycles (minimum 3 cycles for prediction)
- [ ] Outputs: predicted next period start, predicted cycle length, confidence indicator
- [ ] Edge cases: irregular cycles, very short history, very long gaps
- [ ] Full unit test suite — prediction logic must be deterministic and tested
- [ ] KDoc on every public function
- [ ] Document algorithm in `docs/architecture.md`

### Milestone 3.2 — Mood-by-Phase Correlation

- [ ] Map mood entries to cycle phases (menstrual, follicular, ovulatory, luteal)
- [ ] Phase assignment based on cycle prediction output
- [ ] Simple chart: average mood per phase, last 3 months
- [ ] All computation on-device, no external calls
- [ ] Graceful state when insufficient data exists

### Milestone 3.3 — Symptom Patterns

- [ ] Symptom frequency chart: most common symptoms, by cycle phase
- [ ] Simple bar chart using Swift Charts (no third-party charting library)
- [ ] “Insufficient data” state handled gracefully

### Milestone 3.4 — Insights Screen

- [ ] Surface 2–3 plain-language insights based on data patterns
- [ ] Example: “Your cycle has averaged 28 days over the last 3 months”
- [ ] Example: “You most often log fatigue in days 22–26 of your cycle”
- [ ] No speculative or medical claims — factual summaries only
- [ ] All insight strings i18n-ready

**Phase 3 Exit Criteria:** Predictions display correctly with 3+ cycles of data, charts render accurately, all computations verified by unit tests.

-----

## Phase 4 — Birth Control & Settings (Week 5–6)

**Goal:** Practical daily utility features.

### Milestone 4.1 — Birth Control Logging

- [ ] Log type: pill, patch, ring, IUD, implant, other
- [ ] Pill reminder: local notification, no server, fully on-device
- [ ] Log taken / skipped / late
- [ ] Notes field for missed dose context
- [ ] Reminder scheduling uses `UNUserNotificationCenter` — no push server required
- [ ] No prescription data stored — timing and notes only

### Milestone 4.2 — Data Export

- [ ] Export full dataset as encrypted JSON (for backup / transfer)
- [ ] Export as human-readable CSV (for sharing with a healthcare provider)
- [ ] Export triggers iOS share sheet — user controls where it goes
- [ ] Exported files clearly labeled with date
- [ ] “Delete all data” option — single tap, irreversible, confirmation required

### Milestone 4.3 — Local Backup

- [ ] Encrypted backup file written to user-selected location (Files app, iCloud Drive at user’s discretion)
- [ ] Backup is AES-256 encrypted before it leaves the app
- [ ] Restore from backup file
- [ ] Clear UX explanation: “Your backup is encrypted. If you lose your device and your backup, your data cannot be recovered.”
- [ ] Backup/restore documented in `docs/privacy-model.md`

### Milestone 4.4 — Settings Screen

- [ ] App lock: Face ID / Touch ID / PIN toggle
- [ ] Notification preferences
- [ ] Backup and restore
- [ ] Export data
- [ ] Delete all data
- [ ] Language selection (explicit, in addition to system default)
- [ ] About: version, license (AGPL v3), link to GitHub repository, link to privacy policy
- [ ] Open source acknowledgments screen

**Phase 4 Exit Criteria:** Birth control reminders fire correctly on a physical device, backup file exports and restores correctly, delete-all removes all data from the database.

-----

## Phase 5 — Polish, Accessibility & App Store (Week 6–7)

**Goal:** App Store submission ready.

### Milestone 5.1 — UI Polish (Developer-Driven)

- [ ] Consistent spacing, typography, and color system defined in a `DesignTokens` enum
- [ ] Dark mode support (SwiftUI automatic where possible, manual where needed)
- [ ] App icon designed (can use SF Symbols creatively or commission a simple icon)
- [ ] Launch screen
- [ ] Empty states for all screens (first launch, no data yet)
- [ ] Error states for all failure paths

### Milestone 5.2 — Accessibility

- [ ] VoiceOver labels on all interactive elements
- [ ] Dynamic Type support — no hardcoded font sizes
- [ ] Minimum tap target size 44×44pt enforced
- [ ] Color contrast meets WCAG AA minimum
- [ ] Reduce Motion support for any animations

### Milestone 5.3 — Localization

- [ ] Audit all screens for hardcoded strings — zero tolerance
- [ ] Submit English strings to a translation service or community contributors
- [ ] Priority languages for launch: English, Spanish, French, German, Portuguese
- [ ] RTL layout support scaffolded (Arabic, Hebrew — even if not translated at launch)
- [ ] Date and number formatting uses `Locale`-aware formatters throughout

### Milestone 5.4 — Testing Pass

- [ ] Unit tests: KMP domain layer, encryption, prediction algorithm — target 80%+ coverage
- [ ] UI tests: critical paths (onboarding, log a cycle, view insights, export data, delete all data)
- [ ] Manual test on minimum supported iOS version (iOS 16)
- [ ] Manual test on largest supported device and smallest supported device
- [ ] Manual test: airplane mode — all features must work fully offline

### Milestone 5.5 — App Store Submission

- [ ] Privacy Nutrition Label — fill accurately and minimally:
  - Data Not Collected (target this — no analytics, no account, no network data)
- [ ] App Store screenshots (6.7”, 6.1”, iPad if desired)
  - Show real app UI, no marketing claims that can’t be substantiated
- [ ] App description — lead with privacy, be specific about what is not collected
- [ ] Age rating: 12+ (health content)
- [ ] Review notes for App Review: explain the privacy model, local-only architecture
- [ ] Submit for review — budget 1–7 days for first review

**Phase 5 Exit Criteria:** App approved and live on the App Store.

-----

## Phase 6 — Android (Following iOS Launch)

**Goal:** Android MVP with full feature parity, leveraging the KMP shared module.

Because all business logic, data models, database queries, and algorithms live in the KMP shared module, the Android build is primarily a UI task — Jetpack Compose screens consuming the same repositories iOS uses.

### Milestone 6.1 — Android Project Setup

- [ ] Create Android module in `androidApp/`
- [ ] Implement `KeystoreKeyStorage` in `androidMain` (Android Keystore equivalent of iOS Keychain implementation)
- [ ] Implement Android SQLDelight driver
- [ ] Configure Android GitHub Actions CI
- [ ] Set minimum SDK: API 26 (Android 8.0) — broad coverage, modern security APIs

### Milestone 6.2 — Android UI

- [ ] Implement all iOS feature screens in Jetpack Compose
- [ ] Android-native navigation (Navigation Compose)
- [ ] Material Design 3 components — consistent with platform conventions
- [ ] Local notification implementation for birth control reminders

### Milestone 6.3 — Android App Store

- [ ] Google Play privacy declaration (matches iOS: Data Not Collected)
- [ ] Play Store listing, screenshots, description
- [ ] Submit for review

-----

## Clinician Engagement Plan

The PMDD and mental health modules (planned for a future phase, after core launch) require clinical review before shipping. Steps:

1. **Find a clinician:** Target OB/GYN, psychiatrist, or women’s health NP with interest in digital health. Channels: local medical schools, women’s health advocacy organizations, cold outreach via LinkedIn.
1. **Scope of review:** Symptom definitions, severity language, any pattern interpretation language, all disclaimers.
1. **What they review:** The `clinical-disclaimer.md` document and all UI strings related to PMDD and mental health — not the code.
1. **Compensation:** Offer acknowledgment in the app’s About screen and README. If a fee is appropriate, budget accordingly.
1. **Output:** Written sign-off stored in `docs/clinical-disclaimer.md`, versioned in git.

**Do not ship PMDD or mental health modules without this step complete.**

-----

## Sustainability Model

The app is free, AGPL v3, no ads, no data monetization. Sustainability options to evaluate after launch:

- **GitHub Sponsors** — simple, low friction, respects the open source model
- **Open Collective** — transparent finances, good for community trust
- **One-time App Store purchase** — considered later if ongoing costs require it; would require a free tier to preserve accessibility
- **Grants** — digital rights organizations (EFF, FOSS foundations) sometimes fund privacy-first tools

No decision required now. Revisit after first 100 users.

-----

## Risk Register

|Risk                                  |Likelihood    |Impact   |Mitigation                                                                               |
|--------------------------------------|--------------|---------|-----------------------------------------------------------------------------------------|
|KMP/iOS bridging issues cause delays  |Medium        |High     |Prototype the bridge in Week 1 before committing to full feature build                   |
|App Store rejection                   |Medium        |Medium   |Detailed review notes submitted with app; “Data Not Collected” label is a positive signal|
|i18n overhead underestimated          |High          |Medium   |String Catalog scaffolded in Week 1; translation deferred until after feature freeze     |
|No clinician found before PMDD scope  |Low (deferred)|High     |PMDD module explicitly out of scope until review complete                                |
|Security implementation flaw          |Low           |Very High|Encryption documented and reviewable; open source invites audit                          |
|Solo developer burnout / project stall|Medium        |High     |Phased plan with clear exit criteria per phase; community can fork if project stalls     |

-----

## Week-by-Week Summary

|Week|Focus           |Deliverable                                            |
|----|----------------|-------------------------------------------------------|
|1   |Foundation      |Repo live, KMP compiles, encrypted DB working, CI green|
|2   |iOS Setup       |Xcode project, i18n scaffolding, onboarding flow       |
|3   |Core Logging    |Cycle, mood, and symptom logging working on device     |
|4   |Dashboard       |Dashboard, core UX connected end-to-end                |
|5   |Intelligence    |Predictions, insights, charts — all on-device          |
|6   |Utility Features|Birth control reminders, export, backup, settings      |
|7   |Polish & Testing|Accessibility, localization, UI polish, test pass      |
|8   |App Store       |Submission, response to review, launch                 |

*Android follows after iOS launch, leveraging the KMP shared module.*

-----

## Definition of Done — iOS MVP

The iOS MVP is complete when:

- [ ] All Phase 1–5 milestones are checked off
- [ ] Zero hardcoded strings in the UI
- [ ] All public functions have KDoc/DocC comments
- [ ] CI is green on `main`
- [ ] App works fully offline
- [ ] No third-party SDK makes a network call
- [ ] Data persists correctly across app restarts
- [ ] Delete-all removes all data
- [ ] Backup exports and restores correctly
- [ ] App is live on the App Store

-----

*Privacy Period is a personal project. All development is independent of Fortegra Financial or any employer.*
