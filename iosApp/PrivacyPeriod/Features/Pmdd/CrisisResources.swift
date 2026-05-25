// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation

/// A single crisis support line, bundled for offline use.
///
/// The action is a phone or SMS link, never a network call — it works with no
/// connectivity and the app itself contacts no one. Display strings are i18n
/// keys; the numbers are data.
struct CrisisResource: Identifiable {
    let id = UUID()
    /// i18n key for the line's name, e.g. "crisis.us.988".
    let nameKey: String
    /// i18n key for the tappable action label, e.g. "crisis.action.call_988".
    let actionLabelKey: String
    /// tel: or sms: target, or nil for an info-only entry.
    let url: URL?
}

/// Bundled, offline crisis support lines, selected by the device's region.
///
/// This list is reviewed as part of the PME module's clinical/safety sign-off.
/// Regions not covered get a neutral fallback that points to local emergency
/// services rather than an inaccurate number.
enum CrisisResources {
    static func forCurrentRegion() -> [CrisisResource] {
        switch regionCode() {
        case "US": return unitedStates()
        case "GB": return unitedKingdom()
        case "CA": return canada()
        case "AU": return australia()
        case "IE": return ireland()
        default: return generic()
        }
    }

    private static func regionCode() -> String {
        Locale.current.region?.identifier ?? ""
    }

    private static func line(_ nameKey: String, _ actionLabelKey: String, _ urlString: String?) -> CrisisResource {
        CrisisResource(nameKey: nameKey, actionLabelKey: actionLabelKey, url: urlString.flatMap(URL.init(string:)))
    }

    private static func unitedStates() -> [CrisisResource] {
        [
            line("crisis.us.988", "crisis.action.call_988", "tel:988"),
            line("crisis.us.textline", "crisis.action.text_741741", "sms:741741&body=HOME")
        ]
    }

    private static func unitedKingdom() -> [CrisisResource] {
        [
            line("crisis.uk.samaritans", "crisis.action.call_116123", "tel:116123"),
            line("crisis.uk.shout", "crisis.action.text_85258", "sms:85258&body=SHOUT")
        ]
    }

    private static func canada() -> [CrisisResource] {
        [line("crisis.ca.988", "crisis.action.call_988", "tel:988")]
    }

    private static func australia() -> [CrisisResource] {
        [line("crisis.au.lifeline", "crisis.action.call_131114", "tel:131114")]
    }

    private static func ireland() -> [CrisisResource] {
        [line("crisis.ie.samaritans", "crisis.action.call_116123", "tel:116123")]
    }

    private static func generic() -> [CrisisResource] {
        [line("crisis.generic.local", "crisis.action.local", nil)]
    }
}
