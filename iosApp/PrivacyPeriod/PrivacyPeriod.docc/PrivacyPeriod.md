# ``PrivacyPeriod``

A privacy-first, offline women's health tracker.

## Overview

Privacy Period stores all data on the device, encrypted, with no account and no
network calls for its core features. This documentation covers the iOS app layer;
the shared business logic — data models, database, algorithms, and encryption —
lives in the Kotlin Multiplatform `shared` module and is consumed here through the
generated `Shared` framework.

## Topics

### App

- ``PrivacyPeriodApp``
- ``RootView``
- ``OnboardingView``
- ``DashboardView``
