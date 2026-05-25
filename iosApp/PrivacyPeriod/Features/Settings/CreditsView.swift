// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Clinical research credits: the published instruments Privacy Period's screens are
/// built on. Every clinical screen ties to a citable source (full registry on GitHub).
/// Third-party open-source attributions live in the repository's CREDITS.md, not here.
///
/// The entries are bibliographic references (proper nouns, journal names, licenses);
/// they are not localized UI copy. The surrounding chrome (title, intro, section
/// header) is localized.
struct CreditsView: View {
    let onClose: () -> Void

    private struct Credit: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        let url: URL?
        init(_ name: String, _ detail: String, _ urlString: String? = nil) {
            self.name = name
            self.detail = detail
            self.url = urlString.flatMap { URL(string: $0) }
        }
    }

    // Clinical instruments and the peer-reviewed sources that define them. Full
    // citations and conformance reports live in docs/clinical-provenance.md.
    private let research: [Credit] = [
        Credit("DRSP — Daily Record of Severity of Problems",
               "Endicott, Nee & Harrison (2006), Arch Womens Ment Health"),
        Credit("C-PASS scoring",
               "Eisenlohr-Moul et al. (2017), Am J Psychiatry · reference impl. lasy/cpass (CC BY 4.0)",
               "https://github.com/lasy/cpass"),
        Credit("MAC-PMSS", "Frey et al. (2022), BMC Women's Health"),
        Credit("PBAC — Pictorial Blood loss Assessment Chart",
               "Higham et al. (1990), BJOG"),
        Credit("Greene Climacteric Scale", "Greene (1998), Maturitas"),
        Credit("Endometriosis screening score",
               "Chauvet et al. (2021), eClinicalMedicine (CC BY-NC-ND 4.0)"),
        Credit("EHP-30", "Jones et al. (2001), Oxford University Innovation")
    ]

    private let registryURL = URL(
        string: "https://github.com/Privacyperiod/privacy-period/blob/main/docs/clinical-provenance.md"
    )

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "credits.title") {
                DDNavButton(titleKey: "common.done", action: onClose)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("credits.intro")
                        .font(.ddSans(14))
                        .foregroundColor(.ddFg2)
                        .fixedSize(horizontal: false, vertical: true)
                    section("credits.section.research", credits: research)
                    if let registryURL {
                        Link(destination: registryURL) {
                            Text("credits.registry")
                                .font(.ddSans(14, .medium))
                                .foregroundColor(.ddSun)
                        }
                    }
                    Text("credits.repo_license")
                        .font(.ddSans(13))
                        .foregroundColor(.ddFg3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
    }

    private func section(_ titleKey: LocalizedStringKey, credits: [Credit]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey)
                .font(.ddSans(13, .semibold))
                .foregroundColor(.ddFg3)
                .textCase(.uppercase)
            ForEach(credits) { creditRow($0) }
        }
    }

    @ViewBuilder private func creditRow(_ credit: Credit) -> some View {
        if let url = credit.url {
            Link(destination: url) { creditBody(credit, isLink: true) }
                .buttonStyle(.plain)
        } else {
            creditBody(credit, isLink: false)
        }
    }

    private func creditBody(_ credit: Credit, isLink: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(verbatim: credit.name)
                    .font(.ddSans(15, .medium))
                    .foregroundColor(.ddPlumDeep)
                if isLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.ddSun)
                }
            }
            Text(verbatim: credit.detail)
                .font(.ddSans(13))
                .foregroundColor(.ddFg3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
