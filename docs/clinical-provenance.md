# Clinical Provenance Registry

This is the published, auditable map from every clinical screen in Privacy Period
to the validated instrument it implements, the peer-reviewed source that defines
that instrument, the open-source reference used to verify our implementation, and
the conformance report that proves our output matches.

It exists because the clinical layer must **tie out to established science**, in
public. Nothing a clinical screen shows a user is invented by this app; every
clinical item and every score traces to a citable source and a reproducible
conformance check.

> **Not a diagnosis.** These instruments are screening and symptom-tracking
> tools. Privacy Period never states a diagnosis; it reports, factually, how
> tracked symptoms compare to published criteria and directs the user to a
> clinician. See [`clinical-disclaimer.md`](./clinical-disclaimer.md).

## Rules this registry enforces

- A clinical symptom enters the catalog (`symptom_definitions`) only with a
  `clinical_provenance` (instrument), a `provenance_item` (the exact source
  item), and a citation.
- A validated instrument's item set is **never modified**. User-defined symptoms
  (`clinical_provenance = custom`) and the general daily mood/energy check-in are
  **not** clinical and never feed validated scoring or research.
- A clinical module does **not** ship until it has a row here and a published
  conformance report verifying its scoring against an open-source reference.

## Registry

| Screen / module | Instrument | Items | Published source | Open-source reference | Conformance report | Status |
|---|---|---|---|---|---|---|
| PMDD screening | DRSP (Daily Record of Severity of Problems) | 24 (21 symptom items in 11 DSM-5 domains + 3 interference items) | Endicott, Nee & Harrison (2006), *Arch Womens Ment Health* 9(1):41–49 | [`lasy/cpass`](https://github.com/lasy/cpass) `dsm5_dict` (CC BY 4.0) | — (dictionary feeds C-PASS, below) | Implemented |
| PMDD scoring | C-PASS (Carolina Premenstrual Assessment Scoring System) | item → domain → cycle → subject classification | Eisenlohr-Moul et al. (2017), *Am J Psychiatry* 174(1):51–59 | [`lasy/cpass`](https://github.com/lasy/cpass) `R/CPASS_function.R` (CC BY 4.0) | [`cpass-conformance.md`](./cpass-conformance.md) — **PASS, 37/37 cycles, 20/20 subjects** | Implemented, gated |
| PME screening | MAC-PMSS (McMaster Premenstrual & Mood Symptom Scale) | DRSP items (reused) + mood-chart items | Frey et al. (2022), *BMC Women's Health* | TBD (instrument from McMaster; permission via IAPMD) | _pending_ | Planned |
| PMDD-vs-PME differentiation | follicular-baseline vs. luteal-elevation pattern classifier | 7 differentiating mood/cognitive symptoms | Eisenlohr-Moul et al.; MAC-PMSS validation | derived; validated against published case data | _pending_ | Planned |
| Heavy menstrual bleeding | PBAC (Pictorial Blood Loss Assessment Chart) | product/saturation/clot/flooding points | Higham et al. (1990), *BJOG* 97(8):734–739 | published scoring (no code dependency) | _pending_ | Planned |
| Perimenopause | Peri-SS, or Greene Climacteric Scale (permission-free) | per instrument | Peri-SS (2025); Greene (1998) | published scoring | _pending_ | Planned |
| Endometriosis screening | Chauvet questionnaire score (8-item / 5-item) | risk factors + VAS symptom thresholds → weighted score → risk band | Chauvet et al. (2021), *eClinicalMedicine* 44:101259 (CC BY-NC-ND 4.0) | published scoring, clean-room (item wording is a separately-licensed asset) | unit-tested (`EndoScreenScorerTest`, 6/6) | Scoring engine implemented; module/UI pending; gated |
| Endometriosis (quality of life) | EHP-30 (Endometriosis Health Profile) | 30 core items, 5 subscales (+ optional modules) | Jones et al. (2001), Oxford | published scoring (instrument licensed by Oxford University Innovation) | _pending_ | Planned — contingent on license |
| Fertility awareness (symptothermal) | Sensiplan symptothermal method (temperature + mucus double-check) | BBT rule, cervical-mucus peak rule, double-check; mucus/cervix categories | Arbeitsgruppe NFP, *Natürliche Familienplanung heute* (Springer); Frank-Herrmann et al. (2007), *Hum Reprod* 22(5):1310–1319 | drip. (gitlab.com/bloodyhealth/drip) — independent implementation, cross-checked | _pending_ | Planned (backlog) |

> **Fertility awareness is a wellness/tracking tool, not contraception.** The
> Sensiplan rules are public-domain and patent-free; we implement them
> independently with attribution, and the module never uses contraceptive
> framing ("safe day", "green/red day", effectiveness claims). It ships only
> after a regulatory review. The published rules — not any closed algorithm —
> are what the implementation will be audited against.

## How to verify

Each "Implemented" row is reproducible. For C-PASS: install R + the `lasy/cpass`
runtime dependencies, run `cpass()` on the package's bundled `PMDD_data`, and run
`./gradlew :shared:jvmTest --tests "org.privacyperiod.pmdd.CpassConformanceTest"`;
the conformance report documents the full comparison. Future modules follow the
same pattern, each adding its own conformance report linked from the table above.
