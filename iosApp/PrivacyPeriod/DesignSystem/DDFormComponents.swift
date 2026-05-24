// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A simple top bar for modal screens: a centred title with optional leading and
/// trailing text actions (e.g. Cancel / Save).
struct DDNav<Leading: View, Trailing: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ZStack {
            Text(titleKey)
                .font(.ddSans(16, .semibold))
                .foregroundColor(.ddPlumDeep)
            HStack {
                leading
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// A text button styled as a nav action (burnt-orange, sentence case).
struct DDNavButton: View {
    let titleKey: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(titleKey).font(.ddSans(16, .semibold))
        }
        .foregroundColor(.ddSunDeep)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
    }
}

/// One option in a ``DDSegmented`` control.
struct DDSegment<Value: Hashable>: Identifiable {
    let value: Value
    let label: LocalizedStringKey
    var id: Value { value }
}

/// A pill-shaped segmented control. The selected segment fills with plum.
struct DDSegmented<Value: Hashable>: View {
    let segments: [DDSegment<Value>]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    selection = segment.value
                } label: {
                    Text(segment.label)
                        .font(.ddSans(14, .semibold))
                        .foregroundColor(isSelected ? .ddLinen : .ddFg2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isSelected ? Color.ddPlumDeep : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.ddLinen))
        .overlay(Capsule(style: .continuous).stroke(Color.ddSand, lineWidth: 1))
    }
}

/// A labelled field container (label, content, optional help text) matching the
/// design system's DDField.
struct DDFieldContainer<Content: View>: View {
    let labelKey: LocalizedStringKey
    var helpKey: LocalizedStringKey?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(labelKey)
                .font(.ddSans(14, .medium))
                .foregroundColor(.ddFg2)
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                        .fill(Color.ddLinen)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                        .stroke(Color.ddSand, lineWidth: 1)
                )
            if let helpKey {
                Text(helpKey)
                    .font(.ddSans(13))
                    .foregroundColor(.ddFg3)
            }
        }
    }
}
