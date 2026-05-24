# C-PASS Conformance Report

This document is the published proof that Privacy Period's C-PASS implementation
produces output **identical** to the authoritative reference implementation. It
is part of the project's "the code is the privacy policy" auditability commitment
and a required input to clinical sign-off.

> **Not a diagnosis.** The Carolina Premenstrual Assessment Scoring System
> (C-PASS) is a research scoring procedure. Nothing here, and nothing the app
> computes, is a medical diagnosis. The app never tells a user they "have" PMDD;
> it reports, factually, whether their tracked symptoms match the DSM-5 pattern
> and encourages sharing the record with a qualified clinician.

## What is being proven

Privacy Period scores the Daily Record of Severity of Problems (DRSP) using the
C-PASS procedure (Eisenlohr-Moul et al., 2017, *American Journal of Psychiatry*).
Our scorer (`org.privacyperiod.pmdd.CpassScorer`, Kotlin, in the shared module)
is a **clean-room reimplementation written from the published specification** —
it is not a port of any reference source code.

To guarantee correctness, we run our scorer over the same input as the reference
implementation and require that **every scored field, for every cycle and every
subject, matches exactly**. This is enforced automatically by
`CpassConformanceTest` in continuous integration; this document is the
human-readable record of that comparison.

## Reference implementation (the oracle)

| | |
|---|---|
| Reference package | [`lasy/cpass`](https://github.com/lasy/cpass) |
| Package version | 0.1.0 (commit `043bef9`) |
| License | CC BY 4.0 |
| Authors | Symul & Eisenlohr-Moul |
| Reference dataset | `PMDD_data` (bundled example data, 20 subjects, 37 cycles) |
| R version | 4.6.0 |
| Supporting packages | dplyr 1.2.1, tidyr 1.3.2 |

The reference outputs were produced by running, on the bundled `PMDD_data`:

```r
ci  <- as_cpass_data(PMDD_data, sep_event = "menses")
out <- cpass(ci, silent = TRUE)
```

and exporting `out$subject_level_diagnosis` and `out$cycle_level_diagnosis`. The
exported fixtures, the example dataset, and the conformance test all live in the
repository:

- `shared/src/jvmTest/resources/cpass/PMDD_data.csv` — the input.
- `shared/src/jvmTest/resources/cpass/subject_truth.csv` — reference subject output.
- `shared/src/jvmTest/resources/cpass/cycle_truth.csv` — reference cycle output.
- `shared/src/jvmTest/kotlin/.../CpassConformanceTest.kt` — the assertions.

The scorer is pure shared (`commonMain`) code, so verifying it on the JVM proves
the identical logic that executes on iOS.

## The procedure, in brief

1. **Item level** — for each subject, cycle, and DRSP item, compare the
   pre-menstrual window (days −7…−1) with the post-menstrual window (days 4…10).
   An item meets criteria when there are enough observations in both windows, the
   pre-menstrual maximum is high (≥ 4) on at least two days, the pre-to-post drop
   is at least 30% of the subject's score range, and (for PMDD) the symptom
   clears post-menstrually.
2. **Domain level** — the 24 items roll up into 11 DSM-5 symptom domains (item 20
   and the interference items 22–24 are excluded). A domain meets criteria if any
   contributing item does.
3. **Cycle level** — DSM-5 criterion A (a core-emotional domain meets criteria)
   and criterion B (five or more domains meet criteria) yield a per-cycle label:
   no diagnosis, PME, MRMD (A only), or the full premenstrual-dysphoric pattern
   (A and B).
4. **Subject level** — across scored cycles, a label requires at least two
   qualifying cycles and a majority (≥ 50%).

Unknown (missing-data) values propagate exactly as in the reference, which the
conformance test relies upon.

## Result

**PASS — 37/37 cycles and 20/20 subjects match the reference exactly.**

### Subject-level diagnoses

Each row is both the reference output and our output; the conformance test
asserts they are equal. `NA` denotes "not determined" (a single scored cycle).
"Class (dxcat)" is the reference category code: 0 = no diagnosis, 1 = MRMD,
2 = PMDD, 3 = PME.

<!-- generated from subject_truth.csv; verified equal to CpassScorer output -->
| Subject | Cycles | Scored | PMDD cyc | MRMD cyc | PME cyc | PMDD | MRMD | PME | Class (dxcat) | Avg domains |
|---|---|---|---|---|---|---|---|---|---|---|
| 2 | 2 | 2 | 2 | 2 | 2 | TRUE | TRUE | TRUE | 2 | 8.5 |
| 15 | 1 | 1 | NA | NA | NA | NA | NA | NA | NA | 8 |
| 17 | 2 | 2 | 0 | 1 | 0 | FALSE | FALSE | FALSE | 0 | 2.5 |
| 21 | 2 | 2 | 0 | 0 | 0 | FALSE | FALSE | FALSE | 0 | 0.5 |
| 25 | 2 | 2 | 0 | 2 | 1 | FALSE | TRUE | FALSE | 1 | 3 |
| 27 | 2 | 2 | 0 | 1 | 1 | FALSE | FALSE | FALSE | 0 | 2 |
| 33 | 1 | 1 | NA | NA | NA | NA | NA | NA | NA | 3 |
| 36 | 2 | 2 | 1 | 1 | 1 | FALSE | FALSE | FALSE | 0 | 3 |
| 44 | 2 | 2 | 1 | 1 | 1 | FALSE | FALSE | FALSE | 0 | 3.5 |
| 47 | 3 | 3 | 1 | 1 | 1 | FALSE | FALSE | FALSE | 0 | 1.66666666666667 |
| 48 | 1 | 1 | NA | NA | NA | NA | NA | NA | NA | 2 |
| 49 | 2 | 2 | 0 | 1 | 0 | FALSE | FALSE | FALSE | 0 | 3 |
| 60 | 1 | 1 | NA | NA | NA | NA | NA | NA | NA | 7 |
| 95 | 1 | 1 | NA | NA | NA | NA | NA | NA | NA | 3 |
| 117 | 2 | 2 | 1 | 1 | 2 | FALSE | FALSE | TRUE | 3 | 4.5 |
| 122 | 3 | 3 | 0 | 2 | 1 | FALSE | TRUE | FALSE | 1 | 1.66666666666667 |
| 147 | 2 | 2 | 1 | 1 | 1 | FALSE | FALSE | FALSE | 0 | 3 |
| 158 | 2 | 2 | 1 | 2 | 2 | FALSE | TRUE | TRUE | 1 | 5 |
| 162 | 2 | 2 | 2 | 2 | 2 | TRUE | TRUE | TRUE | 2 | 9 |
| 178 | 2 | 2 | 2 | 2 | 2 | TRUE | TRUE | TRUE | 2 | 9 |

### Cycle-level diagnoses

<!-- generated from cycle_truth.csv; verified equal to CpassScorer output -->
| Subject | Cycle | Included | Domains (PME) | Domains (PMDD) | PME | DSM-5 A | DSM-5 B | Classification |
|---|---|---|---|---|---|---|---|---|
| 2 | 1 | TRUE | 10 | 10 | TRUE | TRUE | TRUE | PMDD |
| 2 | 2 | TRUE | 7 | 7 | TRUE | TRUE | TRUE | PMDD |
| 15 | 2 | TRUE | 8 | 8 | TRUE | TRUE | TRUE | PMDD |
| 17 | 1 | TRUE | 4 | 4 | FALSE | TRUE | FALSE | MRMD |
| 17 | 2 | TRUE | 2 | 1 | FALSE | FALSE | FALSE | no diagnosis |
| 21 | 2 | TRUE | 1 | 1 | FALSE | FALSE | FALSE | no diagnosis |
| 21 | 3 | TRUE | 0 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 25 | 2 | TRUE | 4 | 2 | FALSE | TRUE | FALSE | MRMD |
| 25 | 3 | TRUE | 7 | 4 | TRUE | TRUE | FALSE | MRMD |
| 27 | 1 | TRUE | 0 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 27 | 2 | TRUE | 8 | 4 | TRUE | TRUE | FALSE | MRMD |
| 33 | 1 | TRUE | 3 | 3 | FALSE | TRUE | FALSE | MRMD |
| 36 | 1 | TRUE | 6 | 6 | TRUE | TRUE | TRUE | PMDD |
| 36 | 2 | TRUE | 0 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 44 | 1 | TRUE | 0 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 44 | 2 | TRUE | 10 | 7 | TRUE | TRUE | TRUE | PMDD |
| 47 | 1 | TRUE | 3 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 47 | 2 | TRUE | 5 | 5 | TRUE | TRUE | TRUE | PMDD |
| 47 | 3 | TRUE | 0 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 48 | 1 | TRUE | 2 | 2 | FALSE | FALSE | FALSE | no diagnosis |
| 49 | 1 | TRUE | 2 | 2 | FALSE | FALSE | FALSE | no diagnosis |
| 49 | 2 | TRUE | 4 | 4 | FALSE | TRUE | FALSE | MRMD |
| 60 | 2 | TRUE | 7 | 7 | TRUE | TRUE | TRUE | PMDD |
| 95 | 2 | TRUE | 3 | 3 | FALSE | FALSE | FALSE | no diagnosis |
| 117 | 1 | TRUE | 11 | 8 | TRUE | TRUE | TRUE | PMDD |
| 117 | 2 | TRUE | 9 | 1 | TRUE | FALSE | FALSE | PME |
| 122 | 1 | TRUE | 7 | 4 | TRUE | TRUE | FALSE | MRMD |
| 122 | 2 | TRUE | 4 | 1 | FALSE | TRUE | FALSE | MRMD |
| 122 | 3 | TRUE | 1 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 147 | 1 | TRUE | 0 | 0 | FALSE | FALSE | FALSE | no diagnosis |
| 147 | 2 | TRUE | 6 | 6 | TRUE | TRUE | TRUE | PMDD |
| 158 | 1 | TRUE | 10 | 3 | TRUE | TRUE | FALSE | MRMD |
| 158 | 2 | TRUE | 11 | 7 | TRUE | TRUE | TRUE | PMDD |
| 162 | 1 | TRUE | 10 | 10 | TRUE | TRUE | TRUE | PMDD |
| 162 | 2 | TRUE | 10 | 8 | TRUE | TRUE | TRUE | PMDD |
| 178 | 1 | TRUE | 8 | 8 | TRUE | TRUE | TRUE | PMDD |
| 178 | 2 | TRUE | 10 | 10 | TRUE | TRUE | TRUE | PMDD |

## Reproducing this report

1. Install R and the reference package's runtime dependencies (`dplyr`, `tidyr`,
   `stringr`, `magrittr`).
2. Clone [`lasy/cpass`](https://github.com/lasy/cpass), load `PMDD_data` and
   `dsm5_dict`, source `R/data_formating_functions.R` and `R/CPASS_function.R`,
   and run the snippet above to regenerate the `*_truth.csv` fixtures.
3. Run the Kotlin conformance test:
   `./gradlew :shared:jvmTest --tests "org.privacyperiod.pmdd.CpassConformanceTest"`.

## Scope and limitations

- Conformance is established against the `lasy/cpass` R package on its bundled
  example dataset. Reconciliation against the original UNC C-PASS worksheet and
  the SAS/Excel macro is tracked as part of clinical sign-off.
- The validated, human-facing DRSP item wording is a separate licensed instrument
  and is not reproduced here; the app references items structurally.
- The PMDD feature remains disabled in shipped builds until the signed clinical
  disclaimer described in [`clinical-disclaimer.md`](./clinical-disclaimer.md)
  exists. See that document for the gating policy.

## Sources

- Eisenlohr-Moul T.A., et al. (2017). *Toward the Reliable Diagnosis of DSM-5
  Premenstrual Dysphoric Disorder: The Carolina Premenstrual Assessment Scoring
  System (C-PASS).* American Journal of Psychiatry, 174(1), 51–59.
- Endicott J., Nee J., Harrison W. (2006). *Daily Record of Severity of Problems
  (DRSP): reliability and validity.* Archives of Women's Mental Health.
- Symul L., Eisenlohr-Moul T. *cpass: PMDD and MRMD Diagnoses Following C-PASS.*
  R package, CC BY 4.0. https://github.com/lasy/cpass
