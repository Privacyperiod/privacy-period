// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Builds a plain-text clinician-ready report from the Greene Climacteric Scale
/// completions. Like the other clinical reports, it is a structured clinical
/// document (English), leads with the "not a diagnosis" framing, is produced only
/// on explicit export, and contains no identifiers. It reports the per-domain
/// profile over time; Greene has no diagnostic cutoff.
enum GreeneReport {
    static func text(from completions: [GreeneCompletionScore], generatedOn date: Date = Date()) -> String {
        var lines: [String] = []
        lines.append("Privacy Period — Perimenopause symptom profile (Greene Climacteric Scale)")
        lines.append("Generated \(dateString(date))")
        lines.append("")
        lines.append(
            "NOT A DIAGNOSIS. This is a self-tracked symptom profile using the Greene "
                + "Climacteric Scale (Greene, 1998). It has no diagnostic cutoff; it summarises "
                + "symptom severity by domain. Please interpret in clinical context."
        )
        lines.append("")
        if completions.isEmpty {
            lines.append("No questionnaires completed yet.")
            return lines.joined(separator: "\n")
        }
        for completion in completions {
            lines.append(contentsOf: section(completion))
        }
        return lines.joined(separator: "\n")
    }

    private static func section(_ completion: GreeneCompletionScore) -> [String] {
        let result = completion.result
        return [
            "\(dateLabel(completion.date)) (domain score / max):",
            "  Anxiety: \(Int(result.anxiety))/18",
            "  Depression: \(Int(result.depression))/15",
            "  Somatic: \(Int(result.somatic))/21",
            "  Vasomotor: \(Int(result.vasomotor))/6",
            "  Sexual: \(Int(result.sexual))/3",
            "  Psychological (anxiety + depression): \(Int(result.psychological))/33",
            "  Total: \(Int(result.total))/63",
            ""
        ]
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
