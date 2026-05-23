// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A Lucide stroke icon from the asset catalog, rendered as a tintable template.
/// Set the colour with `.foregroundColor`.
struct DDIcon: View {
    let name: String
    var size: CGFloat = 20

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

/// The single primary action per screen — a filled burnt-orange "sun" button.
struct DDPrimaryButton: View {
    let titleKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titleKey)
                .font(.ddSans(16, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .foregroundColor(.ddLinen)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddSun)
        )
    }
}

/// The reusable "this stays on your device" privacy note: a lock icon beside a
/// short, plain reassurance.
struct PrivacyNotice<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DDIcon(name: "lock", size: 20)
                .foregroundColor(.ddPlumDeep)
                .padding(.top, 2)
            content
                .font(.ddSans(13))
                .foregroundColor(.ddFg2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinenDeep)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                .stroke(Color.ddSand, lineWidth: 1)
        )
    }
}
