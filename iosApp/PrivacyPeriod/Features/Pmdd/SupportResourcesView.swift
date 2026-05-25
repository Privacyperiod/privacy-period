// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A calm, non-blocking surface offering crisis support resources.
///
/// It is never a popup or an interruption. In the default state it shows a
/// discreet "Support resources" link that the user can expand; when [prominent]
/// (the gentle escalation used when the suicidal-ideation rating is elevated) it
/// shows the resources expanded. Resources are bundled and offline — tapping them
/// places a call or opens a text; the app contacts no one and shares nothing.
struct SupportResourcesView: View {
    var prominent: Bool = false

    @State private var expanded = false
    private let resources = CrisisResources.forCurrentRegion()

    var body: some View {
        if prominent || expanded {
            card
        } else {
            Button { expanded = true } label: {
                HStack(spacing: 6) {
                    DDIcon(name: "heart", size: 14)
                    Text("pmdd.si.support_link").font(.ddSans(13, .medium))
                }
                .foregroundColor(.ddPlumDeep)
            }
            .buttonStyle(.plain)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                DDIcon(name: "heart", size: 18).foregroundColor(.ddPlumDeep)
                Text("pmdd.si.support_title")
                    .font(.ddSans(15, .semibold))
                    .foregroundColor(.ddPlumDeep)
            }
            Text("pmdd.si.support_intro")
                .font(.ddSans(13))
                .foregroundColor(.ddFg2)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(resources) { resource in
                resourceRow(resource)
            }
            Text("pmdd.si.support_private")
                .font(.ddMono(11))
                .foregroundColor(.ddFg3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08))
        )
    }

    @ViewBuilder
    private func resourceRow(_ resource: CrisisResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(resource.nameKey))
                .font(.ddSans(14, .medium))
                .foregroundColor(.ddPlumDeep)
            if let url = resource.url {
                Link(destination: url) {
                    Text(LocalizedStringKey(resource.actionLabelKey))
                        .font(.ddSans(14, .semibold))
                        .foregroundColor(.ddSunDeep)
                }
            } else {
                Text(LocalizedStringKey(resource.actionLabelKey))
                    .font(.ddSans(14))
                    .foregroundColor(.ddFg2)
            }
        }
    }
}
