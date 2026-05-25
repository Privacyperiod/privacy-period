// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The perimenopause summary: the most recent Greene Climacteric Scale profile —
/// a per-domain symptom-severity breakdown — plus a clinician-ready export. Greene
/// has no diagnostic cutoff, so this reports the profile factually and never states
/// a diagnosis. Part of the gated Perimenopause feature (see `PeriFeature`).
struct GreeneResultsView: View {
    let completions: [GreeneCompletionScore]?
    let onDone: () -> Void

    private var latest: GreeneCompletionScore? { completions?.last }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "greene.results.title") {
                DDNavButton(titleKey: "common.done", action: onDone)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    disclaimer
                    if let latest {
                        profileCard(latest)
                        shareNote
                        exportButton()
                    } else {
                        Text("greene.result.insufficient")
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
            Text("greene.results.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private func profileCard(_ completion: GreeneCompletionScore) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Self.dateLabel(completion.date))
                .font(.ddSans(13, .medium))
                .foregroundColor(.ddFg3)
            ForEach(Self.domains(completion.result), id: \.id) { domain in
                domainRow(domain.key, score: domain.score, max: domain.max)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddLinenDeep.opacity(0.5)))
    }

    private func domainRow(_ key: LocalizedStringKey, score: Int, max: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(key).font(.ddSans(14, .medium)).foregroundColor(.ddPlumDeep)
                Spacer()
                Text(verbatim: "\(score)/\(max)").font(.ddMono(13)).foregroundColor(.ddFg2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ddPlumDeep.opacity(0.1))
                    Capsule().fill(Color.ddSun)
                        .frame(width: max > 0 ? geo.size.width * CGFloat(score) / CGFloat(max) : 0)
                }
            }
            .frame(height: 8)
        }
    }

    private var shareNote: some View {
        Text("greene.results.sharenote")
            .font(.ddSans(14))
            .foregroundColor(.ddFg2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func exportButton() -> some View {
        ShareLink(item: GreeneReport.text(from: completions ?? [])) {
            Text("greene.results.export")
                .font(.ddSans(16, .semibold))
                .foregroundColor(.ddLinen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddSun))
        }
    }

    // Domain rows with each domain's maximum (item count × 3) for the bar scale.
    private struct DomainRow: Identifiable {
        let id: String
        let key: LocalizedStringKey
        let score: Int
        let max: Int
    }

    private static func domains(_ result: GreeneResult) -> [DomainRow] {
        [
            DomainRow(id: "anxiety", key: "greene.domain.anxiety", score: Int(result.anxiety), max: 18),
            DomainRow(id: "depression", key: "greene.domain.depression", score: Int(result.depression), max: 15),
            DomainRow(id: "somatic", key: "greene.domain.somatic", score: Int(result.somatic), max: 21),
            DomainRow(id: "vasomotor", key: "greene.domain.vasomotor", score: Int(result.vasomotor), max: 6),
            DomainRow(id: "sexual", key: "greene.domain.sexual", score: Int(result.sexual), max: 3)
        ]
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
