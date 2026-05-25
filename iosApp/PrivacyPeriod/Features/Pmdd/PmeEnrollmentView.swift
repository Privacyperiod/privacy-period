// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The PME setup screen: the user records the underlying condition they already
/// live with, so their tracking is framed as premenstrual *exacerbation* of that
/// condition rather than a standalone screening.
///
/// This is self-report of an existing, clinician-given diagnosis — not a diagnosis
/// the app makes. The framing stays non-diagnostic throughout. Part of the gated
/// PME feature (see `PmeFeature`).
struct PmeEnrollmentView: View {
    let onCancel: () -> Void
    let onEnroll: (String) -> Void

    @State private var selected: String?

    // Condition-family ids stored in the enrollment config. "other" is the
    // catch-all / prefer-not-to-specify option.
    private let conditions = ["depression", "bipolar", "anxiety", "adhd", "other"]

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "pme.enroll.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.done", isEnabled: selected != nil) {
                    if let selected { onEnroll(selected) }
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    disclaimer
                    Text("pme.enroll.intro")
                        .font(.ddSans(14))
                        .foregroundColor(.ddFg2)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 10) {
                        ForEach(conditions, id: \.self) { condition in
                            conditionRow(condition)
                        }
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
            Text("pme.enroll.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private func conditionRow(_ condition: String) -> some View {
        let isSelected = selected == condition
        return Button {
            selected = condition
        } label: {
            HStack {
                Text(NSLocalizedString("pme.condition.\(condition)", comment: "PME condition family"))
                    .font(.ddSans(16, isSelected ? .semibold : .regular))
                    .foregroundColor(.ddPlumDeep)
                Spacer()
                if isSelected {
                    DDIcon(name: "check", size: 18).foregroundColor(.ddSunDeep)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .fill(isSelected ? Color.ddSun.opacity(0.14) : Color.ddLinen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.ddSunDeep : Color.ddSand, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
