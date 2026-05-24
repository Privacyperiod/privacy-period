// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

/// Builds a plain-text clinician-ready report from a ``CpassResult``.
///
/// The report is a structured clinical document (English), not app UI chrome, so
/// it states the C-PASS screening result factually and leads with the same
/// "not a diagnosis" framing the app uses everywhere. It is produced only when the
/// user explicitly exports, and contains no identifiers.
enum CpassReport {
    static func text(from result: CpassResult, generatedOn date: Date = Date()) -> String {
        var lines: [String] = []
        lines.append("Privacy Period — Premenstrual symptom screening (C-PASS)")
        lines.append("Generated \(dateString(date))")
        lines.append("")
        lines.append(
            "NOT A DIAGNOSIS. This is a self-tracked screening using the Daily Record "
                + "of Severity of Problems (DRSP) and the Carolina Premenstrual Assessment "
                + "Scoring System (C-PASS). Please interpret in clinical context."
        )
        lines.append("")

        if let subject = result.subjects.first {
            lines.append("Cycles tracked: \(subject.nCyclesTotal)")
            lines.append("Cycles with enough data to score: \(subject.nCyclesIncluded)")
            lines.append("Overall screening result: \(subjectText(subject.classification))")
        } else {
            lines.append("No cycles have been scored yet.")
        }

        if !result.cycles.isEmpty {
            lines.append("")
            lines.append("Per cycle:")
            for cycle in result.cycles {
                let domains = "\(cycle.nDomainsMeetingPmdd)/11 DSM-5 domains met"
                lines.append("  Cycle \(cycle.cycle): \(cycleText(cycle.classification)) (\(domains))")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private static func subjectText(_ classification: SubjectClassification?) -> String {
        if classification == SubjectClassification.pmdd {
            return "Matches the DSM-5 premenstrual dysphoric pattern (PMDD criteria)"
        }
        if classification == SubjectClassification.mrmd {
            return "Menstrually related mood pattern (DSM-5 criterion A only)"
        }
        if classification == SubjectClassification.pme {
            return "Premenstrual exacerbation (symptoms rise premenstrually without clearing)"
        }
        if classification == SubjectClassification.noDiagnosis {
            return "Does not match the DSM-5 premenstrual pattern"
        }
        return "Not enough scored cycles to summarize (needs at least two)"
    }

    private static func cycleText(_ classification: CycleClassification?) -> String {
        if classification == CycleClassification.pmdd { return "PMDD pattern" }
        if classification == CycleClassification.mrmd { return "MRMD pattern" }
        if classification == CycleClassification.pme { return "Premenstrual exacerbation" }
        if classification == CycleClassification.noDiagnosis { return "No premenstrual pattern" }
        return "Not scored"
    }
}
