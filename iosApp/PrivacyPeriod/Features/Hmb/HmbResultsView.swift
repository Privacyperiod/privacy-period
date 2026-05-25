// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The heavy-bleeding summary: a factual, non-diagnostic per-cycle PBAC result,
/// plus a clinician-ready export. It never tells the user they "have" a condition;
/// it reports each cycle's PBAC total and classification and points to a clinician.
/// Part of the gated HMB feature (see `HmbFeature`).
struct HmbResultsView: View {
    let cycles: [HmbCycleScore]?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "hmb.results.title") {
                DDNavButton(titleKey: "common.done", action: onDone)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    disclaimer
                    if let cycles, !cycles.isEmpty {
                        ForEach(cycles, id: \.cycleId) { cycleCard($0) }
                        shareNote
                        exportButton(cycles)
                    } else {
                        Text("hmb.result.insufficient")
                            .font(.ddSans(16))
                            .foregroundColor(.ddFg2)
                            .fixedSize(horizontal: false, vertical: true)
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
            Text("hmb.results.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private func cycleCard(_ cycle: HmbCycleScore) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateLabel(cycle.startDate))
                    .font(.ddSans(15, .semibold))
                    .foregroundColor(.ddPlumDeep)
                Text(detailText(cycle.score))
                    .font(.ddSans(13))
                    .foregroundColor(.ddFg3)
            }
            Spacer()
            classificationBadge(cycle.score.classification)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddLinenDeep.opacity(0.5)))
    }

    private func classificationBadge(_ classification: HmbClassification) -> some View {
        let color = Self.color(classification)
        return Text(Self.classKey(classification))
            .font(.ddSans(12, .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.16)))
    }

    private var shareNote: some View {
        Text("hmb.results.sharenote")
            .font(.ddSans(14))
            .foregroundColor(.ddFg2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func exportButton(_ cycles: [HmbCycleScore]) -> some View {
        ShareLink(item: HmbReport.text(from: cycles)) {
            Text("hmb.results.export")
                .font(.ddSans(16, .semibold))
                .foregroundColor(.ddLinen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddSun))
        }
    }

    private func detailText(_ score: PbacScore) -> String {
        let base = String(format: NSLocalizedString("hmb.result.points", comment: "PBAC points"), Int(score.pbacPoints))
        guard score.hasMeasured else { return base }
        let ml = String(format: NSLocalizedString("hmb.result.measured", comment: "measured mL"), Int(score.measuredMl))
        return "\(base) · \(ml)"
    }

    private static func classKey(_ classification: HmbClassification) -> LocalizedStringKey {
        if classification == HmbClassification.heavy { return "hmb.class.heavy" }
        if classification == HmbClassification.borderline { return "hmb.class.borderline" }
        if classification == HmbClassification.normal { return "hmb.class.normal" }
        return "hmb.class.insufficient"
    }

    // Green → orange → red as severity rises; matches the DDLikert severity ramp.
    private static func color(_ classification: HmbClassification) -> Color {
        if classification == HmbClassification.heavy { return Color(hex: 0xC4453B) }
        if classification == HmbClassification.borderline { return Color(hex: 0xE2A32F) }
        if classification == HmbClassification.normal { return Color(hex: 0x4FA15C) }
        return Color(hex: 0x8A8175)
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
