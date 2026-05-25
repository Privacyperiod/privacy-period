# Credits

Privacy Period is built on published clinical research and open-source software.

## Clinical research & instruments

The clinical instruments each screen implements, the peer-reviewed sources that
define them, and the conformance reports that prove our scoring matches are
documented in the auditable [Clinical Provenance Registry](docs/clinical-provenance.md).
A short version is shown in the app under **Settings → Clinical research**.

| Instrument | Source |
|---|---|
| DRSP — Daily Record of Severity of Problems | Endicott, Nee & Harrison (2006), *Arch Womens Ment Health* |
| C-PASS scoring | Eisenlohr-Moul et al. (2017), *Am J Psychiatry*; reference impl. [`lasy/cpass`](https://github.com/lasy/cpass) (CC BY 4.0) |
| MAC-PMSS | Frey et al. (2022), *BMC Women's Health* |
| PBAC — Pictorial Blood loss Assessment Chart | Higham et al. (1990), *BJOG* |
| Greene Climacteric Scale | Greene (1998), *Maturitas* |
| Endometriosis screening score | Chauvet et al. (2021), *eClinicalMedicine* (CC BY-NC-ND 4.0) |
| EHP-30 | Jones et al. (2001), Oxford University Innovation |

## Open-source software

Privacy Period depends on the following open-source projects (runtime, assets, and
build tooling). These attributions live here rather than in the app UI.

| Project | License | Link |
|---|---|---|
| Kotlin Multiplatform | Apache 2.0 | https://kotlinlang.org |
| SQLDelight | Apache 2.0 | https://github.com/sqldelight/sqldelight |
| SQLCipher | BSD | https://www.zetetic.net/sqlcipher/ |
| SQLiter | Apache 2.0 | https://github.com/touchlab/SQLiter |
| Lucide icons | ISC | https://lucide.dev |
| Instrument Serif · Outfit · IBM Plex Mono | SIL Open Font License | https://fonts.google.com |
| XcodeGen | MIT | https://github.com/yonaskolb/XcodeGen |
| CocoaPods | MIT | https://cocoapods.org |
| SwiftLint | MIT | https://github.com/realm/SwiftLint |
| detekt | Apache 2.0 | https://detekt.dev |
| ktlint | MIT | https://github.com/pinterest/ktlint |

Privacy Period itself is free and open source under the
[GNU AGPL-3.0](LICENSE).
