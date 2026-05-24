// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The PMDD screening summary: a factual, non-diagnostic statement of how the
/// user's tracked symptoms compare to the DSM-5 premenstrual pattern, plus a
/// clinician-ready export.
///
/// This screen never tells the user they "have" a condition. It reports what the
/// C-PASS screening found and directs them to a clinician. Part of the gated PMDD
/// feature (see `PmddFeature`).
struct PmddResultsView: View {
    let result: CpassResult?
    let onDone: () -> Void

    private var subject: SubjectResult? { result?.subjects.first }
    private var scoredCycles: Int { Int(subject?.nCyclesIncluded ?? 0) }
    private var isReady: Bool { scoredCycles >= 2 && subject?.classification != nil }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "pmdd.results.title") {
                DDNavButton(titleKey: "common.done", action: onDone)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    disclaimer
                    summaryCard
                    shareNote
                    if let result, !result.cycles.isEmpty {
                        exportButton(for: result)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            DDIcon(name: "shield-check", size: 18).foregroundColor(.ddPlumDeep)
            Text("pmdd.results.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08))
        )
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(statementKey)
                .font(.ddDisplay(24))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
            if isReady {
                Text(basisText)
                    .font(.ddSans(14))
                    .foregroundColor(.ddFg2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddLinenDeep.opacity(0.5))
        )
    }

    private var shareNote: some View {
        Text("pmdd.results.sharenote")
            .font(.ddSans(14))
            .foregroundColor(.ddFg2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func exportButton(for result: CpassResult) -> some View {
        ShareLink(item: CpassReport.text(from: result)) {
            Text("pmdd.results.export")
                .font(.ddSans(16, .semibold))
                .foregroundColor(.ddLinen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddSun)
                )
        }
    }

    private var statementKey: LocalizedStringKey {
        guard isReady, let classification = subject?.classification else {
            return "pmdd.result.insufficient"
        }
        if classification == SubjectClassification.pmdd { return "pmdd.result.pmdd" }
        if classification == SubjectClassification.mrmd { return "pmdd.result.mrmd" }
        if classification == SubjectClassification.pme { return "pmdd.result.pme" }
        return "pmdd.result.none"
    }

    private var basisText: String {
        String(format: NSLocalizedString("pmdd.results.basis", comment: "scored cycle count"), scoredCycles)
    }
}
