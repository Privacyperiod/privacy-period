// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Builds a plain-text clinician-ready report from the endometriosis screening
/// result. Like the other clinical reports, it is a structured clinical document
/// (English), leads with the "not a diagnosis" framing, is produced only on
/// explicit export, and contains no identifiers.
enum EndoScreenReport {
    static func text(from result: EndoScreenResult, generatedOn date: Date = Date()) -> String {
        var lines: [String] = []
        lines.append("Privacy Period — Endometriosis screening")
        lines.append("Generated \(dateString(date))")
        lines.append("")
        lines.append(
            "NOT A DIAGNOSIS. This is a self-tracked screening using the validated "
                + "questionnaire score of Chauvet et al. (2021), eClinicalMedicine. It "
                + "estimates whether endometriosis is worth discussing with a clinician; it "
                + "does not diagnose. Please interpret in clinical context."
        )
        lines.append("")
        lines.append("8-item score: \(Int(result.extendedScore)) — \(riskText(result.extendedRisk))")
        lines.append("5-item score: \(Int(result.briefScore)) — \(riskText(result.briefRisk))")
        return lines.joined(separator: "\n")
    }

    private static func riskText(_ risk: EndoRiskLevel) -> String {
        if risk == EndoRiskLevel.veryHigh { return "very high screening risk" }
        if risk == EndoRiskLevel.high { return "high screening risk" }
        if risk == EndoRiskLevel.intermediate { return "intermediate screening risk" }
        return "low screening risk"
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
