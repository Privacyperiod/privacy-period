// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The PME screening summary: a factual, non-diagnostic statement of the
/// PMDD-vs-PME pattern the user's tracked symptoms show, plus a clinician-ready
/// export.
///
/// This screen never tells the user they "have" a condition or PME. It reports the
/// observed cyclical pattern — whether symptoms clear after the period (PMDD-like)
/// or persist and worsen premenstrually (exacerbation) — and directs them to a
/// clinician. Part of the gated PME feature (see `PmeFeature`).
struct PmeResultsView: View {
    let result: PmePatternResult?
    let onDone: () -> Void

    private var isReady: Bool { result?.isReady ?? false }
    private var scoredCycles: Int { result?.scoredCycles ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "pme.results.title") {
                DDNavButton(titleKey: "common.done", action: onDone)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    disclaimer
                    summaryCard
                    shareNote
                    if let result, isReady {
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
            Text("pme.results.disclaimer")
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
        Text("pme.results.sharenote")
            .font(.ddSans(14))
            .foregroundColor(.ddFg2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func exportButton(for result: PmePatternResult) -> some View {
        ShareLink(item: PmePatternReport.text(from: result)) {
            Text("pme.results.export")
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
        guard isReady, let pattern = result?.pattern else {
            return "pme.result.insufficient"
        }
        if pattern == CyclicityPattern.pmddConsistent { return "pme.result.pmdd_pattern" }
        if pattern == CyclicityPattern.pmeConsistent { return "pme.result.pme_pattern" }
        if pattern == CyclicityPattern.ongoingNoCyclicalChange { return "pme.result.ongoing" }
        if pattern == CyclicityPattern.noCyclicalPattern { return "pme.result.none" }
        return "pme.result.indeterminate"
    }

    private var basisText: String {
        String(format: NSLocalizedString("pme.results.basis", comment: "scored cycle count"), scoredCycles)
    }
}
