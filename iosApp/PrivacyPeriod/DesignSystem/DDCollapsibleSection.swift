// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A titled, collapsible group of rows used to organise the home screen (Tracking,
/// Screening). The header shows the section title and a chevron; tapping it expands
/// or collapses the contents. Expanded by default so nothing is hidden on first view.
struct DDCollapsibleSection<Content: View>: View {
    let titleKey: LocalizedStringKey
    @State private var expanded: Bool
    let content: Content

    init(
        titleKey: LocalizedStringKey,
        initiallyExpanded: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.titleKey = titleKey
        _expanded = State(initialValue: initiallyExpanded)
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(titleKey)
                        .font(.ddSans(13, .semibold))
                        .foregroundColor(.ddFg3)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.ddFg3)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)
            if expanded {
                content
            }
        }
    }
}
