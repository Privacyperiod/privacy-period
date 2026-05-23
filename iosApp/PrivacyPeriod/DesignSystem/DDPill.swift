// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A small, non-interactive informational capsule (e.g. "Encrypted").
struct DDPill: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(.ddSans(13, .medium))
            .foregroundColor(.ddFg2)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule(style: .continuous).fill(Color.ddLinenDeep))
            .overlay(Capsule(style: .continuous).stroke(Color.ddSand, lineWidth: 1))
    }
}

/// A simple left-aligned flow layout that wraps its subviews onto new rows when
/// they run out of horizontal space.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var posX: CGFloat = 0
        var posY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if posX + size.width > maxWidth, posX > 0 {
                posX = 0
                posY += rowHeight + spacing
                rowHeight = 0
            }
            posX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, posX - spacing)
        }
        return CGSize(width: min(maxWidth, widest), height: posY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var posX = bounds.minX
        var posY = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if posX + size.width > bounds.maxX, posX > bounds.minX {
                posX = bounds.minX
                posY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: posX, y: posY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            posX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
