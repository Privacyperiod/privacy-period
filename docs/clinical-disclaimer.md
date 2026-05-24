# Clinical Disclaimer & PMDD Gating Policy

> **STATUS: DRAFT — NOT YET CLINICALLY REVIEWED OR SIGNED.**
> Until this document is reviewed and signed off by a qualified clinician, the
> PMDD / premenstrual-symptom screening feature **must remain disabled in every
> shipped build.** The scoring engine may be present and tested in the codebase,
> but no user-facing PMDD screening, result, or export may be enabled.

## Why this gate exists

Privacy Period's project rules forbid medical claims and require that the PMDD and
mental-health modules stay out of shipped builds until clinical review is
complete. The C-PASS scoring engine has been built and proven to match the
reference implementation (see [`cpass-conformance.md`](./cpass-conformance.md)),
but a correct algorithm is not the same as a responsible user-facing feature.
This document is the single switch that authorizes that feature.

## What the feature may and may not say

When eventually enabled, the feature is bound by these rules, which a clinician
must confirm are adequate:

- **Never a diagnosis.** The app must not state or imply that a user "has" PMDD,
  MRMD, PME, or any condition. C-PASS is a research scoring procedure, not a
  diagnostic instrument, and a phone app is not a medical device.
- **Factual framing only.** Acceptable: "Your tracked symptoms over these cycles
  match the DSM-5 premenstrual pattern. Bring this record to a qualified
  clinician." Not acceptable: any interpretive, prescriptive, or reassuring
  clinical statement.
- **Clinician-directed.** Every result must point the user toward a qualified
  professional and offer a clinician-ready export of the underlying record.
- **No urgency or alarm.** Language must be calm and non-pathologizing.
- **Crisis resources.** The clinician must advise whether and how to surface
  mental-health crisis resources.

## What must be true before sign-off

- [ ] A qualified clinician has reviewed the C-PASS scoring logic and the
      conformance report.
- [ ] A qualified clinician has reviewed and approved every user-facing string in
      the PMDD feature (entry prompts, results, export, disclaimers).
- [ ] The DRSP item wording to be displayed has appropriate permission/licensing.
- [ ] Reconciliation against the original UNC C-PASS worksheet and SAS/Excel macro
      is complete (or explicitly deemed unnecessary, with rationale).
- [ ] This disclaimer text is finalized and approved for display in-app.

## Sign-off

When all of the above are satisfied, a reviewer completes this block, the feature
gate is flipped on in code, and this `STATUS` banner is removed.

| Field | Value |
|---|---|
| Reviewer name | _pending_ |
| Credentials | _pending_ |
| Date | _pending_ |
| Scope reviewed | _pending_ |
| Signature / reference | _pending_ |

Until this block is completed, treat the feature as **disabled**.
