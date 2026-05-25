// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation

/// Looks up the official, licensed definition for a clinical screening item.
///
/// The instrument wording (DRSP, MAC-PMSS, …) is licensed content and is **not**
/// part of this open-source repository. When the licensed definitions asset has
/// been dropped into the app bundle (at clinical/legal sign-off), this returns the
/// official text verbatim; otherwise it returns `nil` and the UI shows a neutral
/// "available after licensing" state.
///
/// No definition text is ever fabricated or paraphrased here — by design, the
/// open-source build ships with no definitions, and only the real instrument text
/// is ever surfaced. See `instrument-licensing.md` for the licensing path.
enum InstrumentDefinitions {
    /// The validated instrument an item is drawn from, shown as provenance even
    /// when the licensed wording itself is not present.
    enum Instrument: String {
        case drsp = "DRSP"
        case macPmss = "MAC-PMSS"
    }

    /// An official item definition loaded from the licensed asset.
    struct Definition {
        let instrument: Instrument
        /// The official item definition, reproduced verbatim from the licensed
        /// instrument under its license. Never paraphrased.
        let text: String
    }

    /// The official definition for a symptom id, or `nil` when the licensed asset
    /// is not bundled (the open-source default).
    static func definition(for symptomId: String) -> Definition? {
        bundledDefinitions[symptomId]
    }

    /// The instrument an item belongs to — known from the id even without the
    /// licensed text, so the neutral state can still name its source.
    static func instrument(for symptomId: String) -> Instrument {
        symptomId.hasPrefix("macpmss_") ? .macPmss : .drsp
    }

    /// Definitions loaded from the licensed, git-ignored asset when present.
    /// Empty in the open-source build.
    private static let bundledDefinitions: [String: Definition] = loadBundled()

    /// Loads `ClinicalDefinitions.plist` from the app bundle if the licensed asset
    /// has been injected. The asset is not committed; absent it, no definitions
    /// are shown. Expected shape: `[symptomId: ["instrument": "DRSP"|"MAC-PMSS",
    /// "text": "<official definition>"]]`.
    private static func loadBundled() -> [String: Definition] {
        guard
            let url = Bundle.main.url(forResource: "ClinicalDefinitions", withExtension: "plist"),
            let raw = NSDictionary(contentsOf: url) as? [String: [String: String]]
        else {
            return [:]
        }
        var result: [String: Definition] = [:]
        for (id, fields) in raw {
            guard
                let text = fields["text"],
                let instrumentRaw = fields["instrument"],
                let instrument = Instrument(rawValue: instrumentRaw)
            else { continue }
            result[id] = Definition(instrument: instrument, text: text)
        }
        return result
    }
}
