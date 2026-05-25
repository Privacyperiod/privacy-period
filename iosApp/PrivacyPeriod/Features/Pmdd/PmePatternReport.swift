// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Builds a plain-text clinician-ready report from a PME pattern result.
///
/// Like ``CpassReport``, this is a structured clinical document (English), not app
/// UI chrome. It states the PMDD-vs-PME differentiation factually, leads with the
/// "not a diagnosis" framing, is produced only on explicit export, and contains no
/// identifiers. It reports a *pattern* — never the underlying condition or PME
/// itself as a diagnosis.
enum PmePatternReport {
    static func text(from result: PmePatternResult, generatedOn date: Date = Date()) -> String {
        var lines: [String] = []
        lines.append("Privacy Period — Premenstrual pattern screening (PMDD vs. PME)")
        lines.append("Generated \(dateString(date))")
        lines.append("")
        lines.append(
            "NOT A DIAGNOSIS. This is a self-tracked screening using the Daily Record "
                + "of Severity of Problems (DRSP), comparing follicular-phase and luteal-phase "
                + "symptom levels. It does not diagnose any condition or its premenstrual "
                + "exacerbation. Please interpret in clinical context."
        )
        lines.append("")
        if let condition = result.condition {
            lines.append("Self-reported underlying condition family: \(conditionText(condition))")
        }
        lines.append("Cycles with enough data to score: \(result.scoredCycles)")

        if result.isReady {
            lines.append("Observed pattern: \(patternText(result.pattern))")
            lines.append("")
            lines.append("Per differentiating symptom (DRSP item — follicular vs. luteal mean, 1–6):")
            for symptom in result.classification.symptoms {
                let follicular = meanText(symptom.follicularMean)
                let luteal = meanText(symptom.lutealMean)
                lines.append("  DRSP\(symptom.item): \(follicular) → \(luteal)")
            }
        } else {
            lines.append("Observed pattern: not enough scored cycles yet (needs at least two).")
        }
        return lines.joined(separator: "\n")
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private static func meanText(_ mean: KotlinDouble?) -> String {
        guard let mean else { return "—" }
        return String(format: "%.1f", mean.doubleValue)
    }

    // The config may hold several comma-separated families (comorbidity is common).
    private static func conditionText(_ config: String) -> String {
        config.split(separator: ",").map { familyText(String($0)) }.joined(separator: ", ")
    }

    private static func familyText(_ id: String) -> String {
        switch id {
        case "depression": return "Depressive disorder"
        case "bipolar": return "Bipolar disorder"
        case "anxiety": return "Anxiety disorder"
        case "adhd": return "ADHD"
        default: return "Other / unspecified"
        }
    }

    private static func patternText(_ pattern: CyclicityPattern) -> String {
        if pattern == CyclicityPattern.pmddConsistent {
            return "Low follicular baseline rising premenstrually (consistent with a PMDD-like pattern)"
        }
        if pattern == CyclicityPattern.pmeConsistent {
            return "Elevated follicular baseline rising further premenstrually "
                + "(consistent with premenstrual exacerbation)"
        }
        if pattern == CyclicityPattern.ongoingNoCyclicalChange {
            return "Symptoms elevated across the cycle without a clear premenstrual rise"
        }
        if pattern == CyclicityPattern.noCyclicalPattern {
            return "No clear cyclical pattern in tracked symptoms"
        }
        return "Tracked symptoms do not fit a single pattern yet"
    }
}
