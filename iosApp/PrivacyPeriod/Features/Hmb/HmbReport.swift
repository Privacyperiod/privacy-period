// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Builds a plain-text clinician-ready report from the HMB per-cycle PBAC scores.
///
/// Like the other clinical reports, this is a structured clinical document
/// (English), not app UI chrome. It states the PBAC result factually, leads with
/// the "not a diagnosis" framing, is produced only on explicit export, and
/// contains no identifiers.
enum HmbReport {
    static func text(from cycles: [HmbCycleScore], generatedOn date: Date = Date()) -> String {
        var lines: [String] = []
        lines.append("Privacy Period — Heavy menstrual bleeding screening (PBAC)")
        lines.append("Generated \(dateString(date))")
        lines.append("")
        lines.append(
            "NOT A DIAGNOSIS. This is a self-tracked screening using the Pictorial Blood "
                + "Loss Assessment Chart (PBAC; Higham et al., 1990). A PBAC total of 100 or more "
                + "(76 secondary), or a measured volume of 80 mL or more, suggests heavy menstrual "
                + "bleeding. Please interpret in clinical context."
        )
        lines.append("")
        if cycles.isEmpty {
            lines.append("No cycles with logged flow yet.")
        } else {
            lines.append("Per cycle:")
            for cycle in cycles {
                let summary = "\(detail(cycle.score)) — \(classText(cycle.score.classification))"
                lines.append("  \(dateLabel(cycle.startDate)): \(summary)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func detail(_ score: PbacScore) -> String {
        let base = "\(Int(score.pbacPoints)) PBAC points"
        guard score.hasMeasured else { return base }
        return "\(base), \(Int(score.measuredMl)) mL measured"
    }

    private static func classText(_ classification: HmbClassification) -> String {
        if classification == HmbClassification.heavy { return "Heavy" }
        if classification == HmbClassification.borderline { return "Borderline" }
        if classification == HmbClassification.normal { return "Within typical range" }
        return "Not enough data"
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private static func dateLabel(_ isoDate: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: isoDate) else { return isoDate }
        let out = DateFormatter()
        out.dateStyle = .medium
        return out.string(from: date)
    }
}
