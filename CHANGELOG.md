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
  iOS 16+) generated with XcodeGen, linking the Kotlin Multiplatform `shared`
  module as a framework via a Gradle build phase. Includes SwiftLint, a
  `Localizable.xcstrings` string catalog, a DocC catalog, and an iOS CI workflow.
