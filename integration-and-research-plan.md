# Privacy Period — Open Source Integration & Research Architecture

**Companion document to** `privacy-period-project-plan.md`
**Status:** Design — to be refined as components are implemented

---

## Part 1: Purpose

This document covers two questions:

1. **How does each external open source component get used in Privacy Period, concretely?** Which are direct dependencies, which are study references, which are clinical frameworks to implement from published specifications, and how do their licenses interact with AGPL v3.
2. **How can Privacy Period support PMDD and menstrual cycle research without compromising the privacy guarantees that are the entire point of the app?** A novel privacy architecture is proposed below — ambitious, but grounded in techniques that are mature in adjacent fields (mobile telemetry, medical statistics, distributed systems).

The end goal: an integrated experience where the user perceives a single, coherent app, and a research contribution model that gives meaningful value back to the women's health research community without ever putting a single identifiable user at risk.

> **Update (2026-05-21): the research contribution model (the second question above, detailed in Part 4) is backburnered.** Current work is purely about question 1 — leveraging external open source components and clinical frameworks for the on-device app. Research Mode is parked and must not drive any present decision (dependencies, architecture, privacy claims, or App Store label).

---

## Part 2: License Compatibility Reference

Privacy Period is AGPL v3. Every external component below has been checked for compatibility. This is the framework:

| External License | Include in AGPL v3 source? | OK in the App Store build? | Notes |
|---|---|---|---|
| MIT | Yes | Yes | Preserve original license file and copyright notice |
| Apache 2.0 | Yes | Yes | Preserve NOTICE file, license, and any modifications notice |
| BSD (2 or 3-clause) | Yes | Yes | Preserve license file and copyright notice |
| MPL 2.0 | Yes | Yes | File-level copyleft — keep modified files MPL-licensed |
| GPL v3 | Source-compatible (AGPL §13) | **Only if you own the copyright** | Apple's terms impose usage restrictions that the GPL "no further restrictions" clause forbids (cf. the VLC App Store removal). You can grant an App Store exception for **your own** code; you **cannot** for third-party GPL code you don't own — so a third-party GPL dependency can make the app un-distributable on the App Store. |
| LGPL | Yes | **Problematic on iOS** | The LGPL relink requirement conflicts with static linking + App Store distribution. Avoid in the iOS target unless you can satisfy the relink clause (hard on iOS). |
| AGPL v3 | Yes (this is the project license) | Yes — as the copyright holder | Same usage-restriction tension as GPL, but resolved because the project holds copyright and can grant the necessary App Store permission. Keep a contributor posture that preserves this (contributions under AGPL, project able to grant the exception). |
| Proprietary / Custom | Case by case | Case by case | Default no |

**Important:** "License compatible" does not mean "code is yours." Any code derived from another project must preserve attribution and original license headers in addition to the AGPL header.

**Also important — copyleft vs. App Store distribution:** Source-license compatibility is *not* the same as being App-Store-distributable. Apple's terms impose usage restrictions (device limits, DRM) that the GPL/AGPL "no further restrictions" clause forbids — which is why GPL apps have been pulled from the App Store. The project ships its **own** AGPL code by granting the necessary App Store permission as the copyright holder, but it **cannot** grant that permission for third-party GPL/LGPL code it does not own. Practical rule: for anything linked into the iOS build, prefer MIT / Apache-2.0 / BSD / MPL-2.0; treat a third-party GPL/LGPL dependency as a red flag requiring legal review before adoption.

---

## Part 3: Component Integration Plan

Each component below is categorized as one of:

- **Direct dependency** — pulled in via package manager, version-pinned
- **Reference implementation** — read and understood; you write your own clean version
- **Clinical framework** — published specification implemented in code
- **Partnership** — relationship with an organization, not code

---

### 3.1 SQLCipher + SQLDelight (Direct Dependency)

**Role:** Encrypted local database — the backbone of all data storage.

**Licenses:**
- SQLCipher: BSD-style (Zetetic LLC). Compatible with AGPL.
- SQLDelight: Apache 2.0. Compatible with AGPL.

**Cipher mode — resolved 2026-05-21:**

The binding constraint was relaxed from "AES-256-GCM" to **"AES-256 authenticated encryption"** across the project docs (`agentic-instructions.md`, `privacy-period-project-plan.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`). The reason: SQLCipher does **not** use GCM — SQLCipher 4 encrypts with **AES-256-CBC**, authenticates with **HMAC-SHA-512** (encrypt-then-MAC), and derives keys via **PBKDF2-HMAC-SHA-512**. That is a sound authenticated-encryption construction (confidentiality + integrity) and the de-facto standard for encrypted SQLite, so it satisfies the relaxed constraint while keeping the standard, well-audited SQLCipher path. The alternative — holding GCM literally — would have meant dropping SQLCipher and hand-rolling GCM file/field encryption over plain SQLDelight, which is more code and less audited.

**Why this combination:**

SQLDelight provides type-safe SQL with shared schemas across iOS and Android via KMP. SQLCipher provides transparent AES-256 encryption of the SQLite database file. Together, they give you a single shared schema (`.sq` files in `commonMain`) and encrypted storage on both platforms — exactly the architecture you need.

**Integration steps:**

1. Add SQLDelight Gradle plugin to the KMP shared module.
2. Set `linkSqlite = false` in the SQLDelight database config — this prevents the default SQLite from being linked, which would conflict with SQLCipher.
3. Add SQLCipher as an iOS dependency via Swift Package Manager (preferred over CocoaPods to keep the iOS build modern).
4. Add SQLCipher for Android via the `net.zetetic:android-database-sqlcipher` Gradle dependency.
5. Create platform-specific `DatabaseDriverFactory` implementations:
   - `iosMain` uses `NativeSqliteDriver` configured with the SQLCipher pragma.
   - `androidMain` uses `AndroidSqliteDriver` with the SQLCipher helper.
6. The encryption key is generated on first launch using `CryptoKit` (iOS) or `KeyGenerator` (Android), stored in Keychain/Keystore, and retrieved by the driver factory at app launch.

**What to write yourself:**

- The `DatabaseDriverFactory` interface and both platform implementations
- The `KeyProvider` interface and both platform implementations (Keychain and Keystore)
- Wrapper layer that ensures keys are never logged, printed, or accessible outside the secure enclave APIs

**What you must document:**

- `docs/encryption.md` — explain the threat model the encryption protects against (device theft, file system access) and what it does not protect against (compromised running process, OS-level attacks)
- Inline comments on every key handling function

**Risks:**

- SQLCipher version compatibility with SQLDelight changes occasionally — version-pin both
- Migrating from unencrypted to encrypted later is painful; start encrypted from day one
- SQLCipher adds ~3 MB to the iOS binary size

---

### 3.2 KmpSqlencrypt (Evaluate, Possibly Direct Dependency)

**Role:** Higher-level Kotlin Multiplatform wrapper around SQLCipher.

**License:** Check at evaluation time (likely Apache or MIT based on the maintainer's other work).

**Why consider it:**

KmpSqlencrypt bundles SQLCipher with OpenSSL 3.0 and provides a KMP-native API. It may save significant setup time compared to wiring SQLDelight + SQLCipher manually. The trade-off: it's a smaller project (less battle-tested), and an additional layer between your code and the underlying database.

**Evaluation plan:**

In Phase 1, prototype both approaches in a throwaway branch:

1. Branch A: SQLDelight + raw SQLCipher (the documented Touchlab pattern)
2. Branch B: KmpSqlencrypt

Compare on:
- Build complexity
- Binary size impact
- Maintenance activity (commit frequency, open issues)
- Documentation quality
- Whether it preserves SQLDelight type-safety

**Decision criterion:** Pick the simpler, more maintained path. If KmpSqlencrypt is well-maintained and reduces complexity meaningfully, use it. Otherwise, stick with the documented SQLDelight + SQLCipher pattern.

---

### 3.3 Ephira (Reference Implementation)

**Source:** `github.com/adulbrich/ephira`
**License:** MIT
**Tech stack:** React Native — **not directly reusable code**

**Why it matters:**

Ephira is the closest existing app to what Privacy Period is trying to be — local-first, encrypted, biometric-locked, MIT open source. Their privacy architecture and UX decisions are valuable reference material.

**What to extract (concepts, not code):**

- **Privacy model documentation** — how they explain their guarantees to users
- **Biometric lock UX** — how the lock screen, fallback PIN, and recovery flow work
- **Data model** — what entities they track (symptoms, moods, medications, notes)
- **Export format** — what users actually need when they export their data
- **Calendar visualization** — their filter-based legend pattern is good UX

**What not to do:**

- Do not copy code. Different language, different framework, different license obligations.
- Do not assume their algorithm choices are optimal. Read their issues to see what users have asked for and what's been hard.

**Action item for Phase 1:**

- Clone Ephira, build it, use it for a week as a user
- Document UX patterns worth adopting in `docs/ux-references.md`
- Note what frustrated you as a user — those are differentiation opportunities

---

### 3.4 drip. (Reference Implementation — Algorithms)

**Source:** `gitlab.com/bloodyhealth/drip`
**License:** Verify at evaluation time
**Tech stack:** React Native with native modules — **not directly reusable code**

**Why it matters:**

drip. is the most algorithmically sophisticated open source period tracker. They publish documentation on how their fertility awareness and bleeding prediction algorithms work in their wiki. Their symptothermal method implementation is well-considered.

**What to extract:**

- **Prediction algorithm logic** — read their wiki documentation on how cycle length predictions handle irregular cycles, anovulatory cycles, and limited history
- **Symptothermal method** — if you ever add fertility awareness features beyond MVP (deferred), their reference implementation is the right starting point
- **Iconography** — they use a thoughtful symptom icon set; consider commissioning similar or contributing back

**Implementation approach for Privacy Period:**

Read drip's algorithm documentation, then implement your own version in Kotlin in `shared/src/commonMain/kotlin/org/privacyperiod/domain/cycle/`. Write it from first principles, not from their code. Cite the documentation in a KDoc comment on your implementation:

```kotlin
/**
 * Predicts next cycle start date using a rolling average of recent cycles.
 *
 * Algorithm approach informed by published research on cycle length
 * variability and the prediction methodology documented by the drip.
 * project (gitlab.com/bloodyhealth/drip wiki, "Cycle prediction").
 *
 * This implementation is independent and written from first principles.
 */
```

This is the right way to honor open source: learn, attribute, write your own.

---

### 3.5 Menstrudel (Reference Only)

**Source:** `github.com/J-shw/Menstrudel`
**License:** Verify at evaluation time
**Tech stack:** Flutter — **not directly reusable code**

**Why it matters:**

Smaller, simpler codebase than Ephira or drip. Useful as a sanity check: if a feature is simpler in Menstrudel, your implementation might be over-engineered.

**Action:** Skim only. Not worth a deep read unless a specific feature in Menstrudel surprises you.

---

### 3.6 Daily Record of Severity of Problems (DRSP) — Clinical Framework

**Source:** Endicott, J., Nee, J., Harrison, W. (2006). Daily Record of Severity of Problems (DRSP): reliability and validity. *Archives of Women's Mental Health*, 9(1), 41–49.

**Why it matters:**

The DRSP is the gold-standard clinical instrument for tracking PMDD symptoms. It is the basis for DSM-5 diagnosis. Building your PMDD module around the DRSP rather than a custom symptom set means:

- Clinicians will recognize and trust the exported data
- Users can take meaningful data to their doctor
- Research contributions (Part 4 below) can use a standardized instrument
- Clinical review for the PMDD module becomes much more tractable

**Structure of the DRSP (high level):**

The DRSP consists of 21 items grouped into 11 symptom domains:

- Depressed mood
- Anxiety/tension
- Affective lability
- Anger/irritability
- Decreased interest in usual activities
- Difficulty concentrating
- Lethargy/fatigue
- Appetite changes
- Sleep changes (insomnia/hypersomnia)
- Feeling overwhelmed or out of control
- Physical symptoms (breast tenderness, swelling, joint/muscle pain, weight gain)

Each item is rated daily on a 1–6 scale (1 = not at all, 6 = extreme).

Two functional impact items and one menses indicator complete the instrument.

**Implementation plan:**

1. **Obtain the published paper** — Endicott et al. 2006 is widely available through academic databases and the International Association for Premenstrual Disorders (IAPMD).

2. **Verify usage rights** — The DRSP is published in academic literature. Personal and clinical use is generally permitted; implementing it in a free, non-commercial, open source app is consistent with the spirit of its publication. **Before shipping, formally confirm permissions with the authors or IAPMD** — this is part of the clinical review process and one of the questions to bring to that partnership.

3. **Create a structured DRSP module** in `shared/src/commonMain/kotlin/org/privacyperiod/domain/drsp/`:
   - `DrspItem` — enum of all 21 items with i18n keys
   - `DrspDomain` — enum of the 11 domains, mapping items to domains
   - `DrspEntry` — daily entry with item ratings, functional impact, and menses indicator
   - `DrspRepository` — persistence layer
   - Strict same-day-only entry enforcement (cannot backdate — see C-PASS section below)

4. **UI requirements (PMDD module — out of MVP scope):**
   - Clear explanation that DRSP requires at least 2 complete cycles of daily tracking
   - Visual indicator of tracking completeness
   - Reminder to log daily
   - "Why same-day only?" educational content explaining the clinical reason
   - Export-to-PDF that produces a clinician-ready DRSP report

5. **Translation:** Coordinate with the published translations of the DRSP. The Spanish CTDP-DSM-5 and Turkish PSST validations referenced in the literature provide validated localized versions. Do not translate clinical instruments yourself.

**Strict rule:** The DRSP must not be modified. If users want to track additional symptoms, those go in a separate symptom log — not mixed into the DRSP data. Modifying a clinical instrument invalidates it.

---

### 3.7 Carolina Premenstrual Assessment Scoring System (C-PASS) — Scoring Algorithm

**Source:** Eisenlohr-Moul, T.A. et al. (2017). Toward the Reliable Diagnosis of DSM-5 Premenstrual Dysphoric Disorder: The Carolina Premenstrual Assessment Scoring System. *American Journal of Psychiatry*, 174(1), 51–59.

**Why it matters:**

C-PASS is the published, validated algorithm for converting DRSP daily ratings into a DSM-5 PMDD classification. It achieves 98% agreement with expert clinical diagnosis. It exists as an Excel macro and SAS macro in the published research — meaning the algorithm is fully documented and implementable.

**Critical design implication:**

C-PASS requires that DRSP ratings be made **prospectively** — on the day, not retrospectively. Retrospective ratings are clinically worthless for PMDD diagnosis because memory recall of past symptoms is systematically biased. This means the app must enforce:

- DRSP entries can only be made for today
- DRSP entries can be edited only within the same day (24-hour window)
- The user cannot backfill missing days
- Missing data is preserved as missing — never inferred

This is a hard UX constraint dictated by clinical validity.

**Implementation plan:**

1. **Obtain the C-PASS paper and the published Excel/SAS macros.** The algorithm is described in detail and is implementable in Kotlin from the specification.

2. **Implement `CPassScorer` in KMP `commonMain`:**
   - Input: a sequence of DRSP entries spanning two or more complete cycles
   - Output: a structured classification result (PMDD criteria met / sub-threshold / does not meet criteria) with the specific criteria evaluated
   - The algorithm operates in four dimensions: symptoms, severity, cyclicity, chronicity

3. **Output framing — critically important:**
   - The result must never be presented as a diagnosis
   - User-facing language: "Your tracked symptoms match the pattern described in DSM-5 criteria for PMDD. Share this report with your healthcare provider for evaluation."
   - The actual diagnosis can only be made by a clinician

4. **Test rigorously:**
   - Test against published case examples in the C-PASS paper
   - 100% unit test coverage of the scoring logic
   - Property-based tests for edge cases (irregular cycles, missing data, very short or very long luteal phases)

5. **Document the algorithm in `docs/drsp-cpass.md`** with a clear citation to the original paper.

**License consideration:** The C-PASS algorithm is published in a peer-reviewed journal. Implementing a published algorithm in code is generally permissible (algorithms are not copyrightable in most jurisdictions; specific code implementations are). Your implementation will be independent, with proper academic citation. Confirm this position during the clinical review process.

---

### 3.8 IAPMD — International Association for Premenstrual Disorders (Partnership)

**Source:** `iapmd.org`

**Why it matters:**

IAPMD is the leading patient advocacy and clinical organization for premenstrual disorders. They produce a DRSP-aligned symptom tracker, maintain relationships with the PMDD research community, and have a clear mission alignment with a privacy-first open source app.

**A formal relationship with IAPMD would provide:**

- Connection to clinicians for the required clinical review
- Validation of the DRSP and C-PASS implementations
- Credibility for the PMDD module
- A potential channel for the research contribution model (Part 4)
- A user community that will value and use the app

**Outreach plan:**

1. **Draft an introduction** before any code is written:
   - Personal background and motivation
   - The privacy-first, free, open source philosophy
   - The intent to implement the DRSP and C-PASS faithfully
   - The proposed research contribution model (Part 4)
   - Ask: would they be willing to advise, review, or partner

2. **Initial contact via their website's contact form or info email**

3. **What to offer in return:**
   - Acknowledgment in the app and the repository
   - The app remains free and aligned with their mission
   - Aggregate, anonymized research data they could use (if the research model materializes)
   - A seat in deciding what features are added in the PMDD module
   - A formal advisory role if appropriate

4. **What to ask for:**
   - Permission and guidance on the DRSP implementation
   - Clinical reviewer connection
   - Feedback on user-facing PMDD language
   - Input on the research contribution model

This outreach should begin in **Phase 1**, in parallel with development — not after. Building this relationship takes time and is the gating item for the PMDD module shipping.

---

## Part 4: Privacy-Preserving Research Architecture

> **STATUS: BACKBURNERED — parked 2026-05-21.** Research Mode is deferred indefinitely. It must **not** influence MVP scope, the core app's privacy claims, the dependency set, or the App Store privacy label. Nothing in this Part is to be scaffolded, stubbed, or built until it is explicitly un-parked. It is retained here as preserved design thinking only. While parked, Privacy Period remains a true "no server; data never leaves the device" product, and the "Data Not Collected" App Store label stays valid. Open questions to resolve **if/when** it is revived: (a) whether it belongs in this app at all vs. a separate companion; (b) a single, coherent differential-privacy model with a stated total-epsilon budget (the current Part is a layering of techniques, not one formal guarantee); (c) the small-N utility-vs-privacy tension; (d) reconciling it with the README's "no server in the loop at all" wording.

**This is the novel contribution Privacy Period can make to women's health.**

The premise: There is a fundamental tension in health research apps. Better research requires more data. More data collection conflicts with privacy. Most apps resolve this by collecting data and hoping for trust. Privacy Period proposes resolving it through cryptography, mathematics, and architecture.

The proposed system is called **Research Mode** — entirely opt-in, off by default, with a privacy guarantee strong enough that it can be explained honestly to users.

---

### 4.1 Goals

The research contribution model must achieve all of the following:

1. **No user is ever identifiable** in any data that leaves the device — not by name, email, device ID, IP address, or any combination of attributes.
2. **No two contributions from the same user can be linked** to each other. The same user contributing twice produces two unconnected records.
3. **Researchers receive scientifically useful data** — not so noised or sparse that it can't support real analysis.
4. **Users understand what they're contributing** — the consent flow is clear, specific, and refusable at any time.
5. **The technical architecture is auditable** — because the app is open source, the privacy claims can be verified by anyone.

---

### 4.2 Non-Goals

To keep the system tractable, these are explicitly not goals:

- **Real-time data.** Contributions are batched and delayed.
- **Per-user research participation tracking.** No notion of "this user contributed X times."
- **Sponsor- or researcher-specific data routing.** Aggregate data is published openly or shared with vetted research partners as a single dataset.

---

### 4.3 The User Experience

A user opts into Research Mode through Settings. The opt-in flow includes:

1. **Plain-language explanation** of what is contributed and what is never contributed
2. **Specific examples** of the data that leaves the device, presented as actual contribution records
3. **An explanation of the privacy techniques** used, in lay terms
4. **A revocation explanation** — what happens when they opt out (no future contributions; past anonymous contributions cannot be retrieved or deleted because they cannot be linked to the user)
5. **Granular controls** — they can opt into cycle pattern research separately from PMDD research, separately from mood research

After opting in, contributions happen automatically in the background. The user can view a log of what has been contributed at any time.

---

### 4.4 What Data Is Contributed

**Never contributed under any circumstance:**

- Names, emails, phone numbers, device IDs, advertising IDs, IP addresses
- Raw cycle entry dates (which would allow tracking individual cycles over time)
- Free-text notes
- Birth control specifics (type, brand, prescription details)
- Location data
- Time-of-day signals
- Any data from before the user opted into Research Mode

**Potentially contributed, after privacy transformation:**

- Cycle length statistics (mean, variance, derived as aggregate summaries)
- DRSP score patterns (luteal vs. follicular phase aggregates)
- Symptom frequency by cycle phase, bucketed
- Birth control method category (pill / IUD / patch / etc., not brand or dose)
- Age range (10-year bucket: 18–28, 28–38, etc.)
- Cycle regularity classification (regular / irregular / very irregular)

These are all aggregated, bucketed, and noised before leaving the device.

---

### 4.5 Technical Architecture

The architecture combines four established privacy techniques. Each one alone would be insufficient. Layered, they produce a system with meaningful privacy guarantees.

#### Technique 1: On-Device Aggregation

Raw data never leaves the device. The device computes aggregate summaries locally. Example: instead of contributing "cycle started 2026-04-02, ended 2026-04-07," the device contributes "average cycle length over the last 12 months: 28.3 days."

This is the most important technique. Raw entries never leave the device.

#### Technique 2: Local Differential Privacy

Before any aggregate leaves the device, calibrated random noise is added on-device. This is **local differential privacy** — the noise is added before the data ever reaches a server, so even a fully compromised server cannot recover the true value for any individual.

For numeric values (like average cycle length), Laplace noise with a carefully chosen epsilon parameter is added. For categorical values (like cycle regularity), randomized response is used: with some probability, the device contributes a random answer instead of the true answer.

The epsilon parameter and randomization probabilities are published, audited, and documented. They are chosen to balance research utility with privacy guarantees, in consultation with privacy researchers and clinical researchers.

This technique is mature and is the basis of Apple's iOS keyboard telemetry, Google's RAPPOR, and modern census data publication.

#### Technique 3: k-Anonymity Threshold at Aggregation

Contributions are batched on a server, but never used in research output until at least *k* contributions exist in the same bucket. If 5 women in a particular age range with a particular cycle pattern contribute, but k=50, that data is held but not released. Below k=50, the existence of a single woman with rare characteristics cannot be inferred from the dataset.

Buckets are defined by the combination of researcher-relevant attributes (age range, cycle regularity, birth control category, etc.). The k threshold is set per-analysis based on the privacy researcher's recommendation.

#### Technique 4: Network Anonymization

Contributions are sent through an anonymizing network so that the IP address of the contributing device cannot be associated with the contribution at the receiving server.

Two implementation options, by increasing strength:

- **Option A (simpler):** Use a trusted proxy operated by a non-profit partner (e.g., a privacy-focused organization, or hosted on infrastructure with a no-logs policy). The receiving server only sees the proxy's IP.
- **Option B (stronger):** Route contributions through the Tor network using a hidden service endpoint. No party — not the app developer, not the proxy, not the receiving server — can correlate the contribution to a user's IP address.

Option B is the strongest and the right long-term answer. Option A is acceptable as a starting point, with a documented commitment to move to Option B.

#### Technique 5: No Persistent Contribution Identifier

Each contribution payload is a one-shot anonymous message. The device does not maintain a "contribution session" or include any identifier that would allow two contributions to be correlated.

The server explicitly does not log:
- Receipt timestamps with finer precision than a 24-hour window
- Source proxy connection metadata
- Any header information beyond what the protocol strictly requires

The server code is open source. The deployed server's logs are publicly auditable, or it runs in a verifiable enclave (long-term).

---

### 4.6 Threat Model

The system is designed to resist:

| Threat | Mitigation |
|---|---|
| Compromised server | Local differential privacy ensures noise is added before transmission; raw values are never on the server |
| Compromised network | Network anonymization (proxy or Tor) prevents IP correlation |
| Insider at the publishing organization | All raw contributions are noised; k-anonymity prevents rare-individual identification; no persistent contribution IDs prevent linking |
| Inference attack across multiple contributions | No persistent contribution identifier; each is a one-shot anonymous payload |
| Subpoena or legal compulsion | The server cannot produce data tied to an individual user because no such data exists; the device cannot produce a "list of contributions" because none is retained as linkable |
| App developer turning malicious | Open source code; auditable build; release signing keys held by a multi-party process for a long-term project |

The system is **not** designed to resist:

| Threat | Why not |
|---|---|
| Physical device seizure with user cooperation | User's own data is on their device; that's a separate threat model addressed by encryption and biometric lock |
| Statistical inference on the published aggregates | Differential privacy noises against this, but very small populations may still be inferable; mitigated by k-anonymity but cannot be eliminated entirely |
| User-revealed data outside the app | Out of scope |

These limits are documented honestly in the user-facing privacy explanation.

---

### 4.7 Governance

The research data needs a steward. Options, with tradeoffs:

| Option | Pros | Cons |
|---|---|---|
| App project alone | Simplest | Single point of trust; long-term durability question |
| IAPMD partnership | Clinical credibility, mission alignment | Adds an organizational dependency |
| Academic institution partnership | Strong research infrastructure | Slower processes, IP concerns |
| Independent nonprofit (new or existing privacy-focused) | Strong governance, mission separation | Requires creating or finding the right org |

**Recommendation:** Start with IAPMD as the data steward partner, with a clear written governance agreement. If the project grows, transition to an independent nonprofit foundation that holds and publishes the data under open data licensing.

The governance agreement should specify:

- What data is published openly vs. shared with specific research partners
- How research access is granted (free for academic use, no commercial sale)
- Open data publication cadence
- How the privacy parameters (epsilon, k) are reviewed and updated
- What happens to the dataset if the steward organization dissolves

---

### 4.8 Honest Limitations

This is presented honestly in the app's privacy documentation:

1. **No system is perfectly private.** Differential privacy bounds the information leak; it doesn't eliminate it. The published epsilon parameters quantify the bound.
2. **Statistical anonymity can fail for very rare cases.** A user with an extremely unusual combination of attributes contributes some information about themselves; k-anonymity mitigates but doesn't eliminate this. Users with very rare conditions should consider this when opting in.
3. **Past contributions cannot be retracted.** Because contributions are unlinkable to the user (the entire point), there is no way to "delete my contributions later." Opting out stops future contributions only.
4. **Trust in the open source process is required.** The privacy guarantees depend on the deployed code matching the published source. Reproducible builds and signed releases are part of the long-term plan.

---

### 4.9 Implementation Phases for Research Mode

Research Mode is **explicitly out of scope for the MVP**. It is added later, deliberately, with proper preparation.

**Pre-Research Phase (during MVP development):**

- Outreach to IAPMD about the model
- Conversation with a privacy researcher (academic or industry) about the differential privacy parameters
- Draft of the user-facing privacy explanation, reviewed by both clinical and privacy reviewers
- Open source publication of the research server code, even before it accepts contributions, for public review

**Research Mode Phase 1: Local Aggregation Only**

- On-device aggregation of contributable summaries
- "Show me what would be contributed" preview in Settings
- Nothing is actually sent — the feature is dark-launched for transparency

**Research Mode Phase 2: Network Submission with Option A**

- Trusted proxy submission
- Open server code, publicly auditable
- Small dataset published openly to validate the pipeline
- Continuous external audit invitation

**Research Mode Phase 3: Tor Endpoint (Option B)**

- Hidden service deployment
- Stronger network anonymity guarantee
- Documented migration of users from Option A to Option B

**Research Mode Phase 4: Reproducible Builds**

- Signed, reproducible build pipeline so the binary in the App Store can be verified against the published source
- Multi-party release signing

This is a multi-year roadmap. The MVP can ship without any of it. The architecture's value is the destination, not how fast it's reached.

---

## Part 5: Integrated Experience — The User's Point of View

From the user's perspective, none of the architectural complexity above is visible. The user experience is:

1. **Open the app.** No account creation. No email. No phone number.
2. **A simple onboarding** explains what the app does and that data stays on the device.
3. **Log cycles, moods, symptoms, birth control.** The app is fast and works offline always.
4. **Receive insights** about cycle patterns, mood correlations with cycle phase, and predictions.
5. **Optionally enable the PMDD module** if they suspect PMDD or want to track DRSP. Clinical-grade tracking. A clear, exportable PDF for their doctor.
6. **Optionally enable Research Mode** if they want to contribute anonymously to women's health research. They understand exactly what is contributed and why it cannot be tied to them. *(Backburnered — not in current scope; see the Part 4 status banner.)*
7. **Export, back up, or delete their data** at any time, in one tap.

The integrated experience is built from open source components, clinical frameworks, and a privacy architecture that is unique in the women's health app space — but presented to the user as a single, calm, trustworthy app.

---

## Part 6: Summary Table

| Component | Type | Phase | Action |
|---|---|---|---|
| SQLCipher + SQLDelight | Direct dependency | Phase 1 | Integrate via Touchlab pattern |
| KmpSqlencrypt | Possible direct dependency | Phase 1 | Prototype and evaluate vs. above |
| Ephira | Reference | Phase 1 | Study UX and privacy model |
| drip. | Reference | Phase 3+ | Study prediction algorithms |
| Menstrudel | Reference | Phase 1 | Skim only |
| DRSP | Clinical framework | Post-MVP PMDD module | Implement from published paper |
| C-PASS | Clinical framework | Post-MVP PMDD module | Implement from published paper |
| IAPMD | Partnership | Phase 1 outreach | Begin relationship in parallel with development |
| Research Mode architecture | Original design | **Backburnered (parked)** | Deferred indefinitely; do not build until explicitly un-parked (see Part 4 banner) |

---

*This document evolves alongside the project. Updates should be reflected in the changelog of `docs/architecture.md` once that document exists.*
