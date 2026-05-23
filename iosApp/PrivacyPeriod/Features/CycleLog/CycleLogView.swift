// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The "Log period" form: start date, optional end date, flow intensity, and an
/// optional note. On save it hands the parent a ``CycleDraft`` to persist; the
/// parent also supplies the cancel handler.
struct CycleLogView: View {
    let onCancel: () -> Void
    let onSave: (CycleDraft) -> Void

    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var flow: Flow = .medium
    @State private var notes = ""

    private enum Flow: String, CaseIterable {
        case spotting
        case light
        case medium
        case heavy
    }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "cyclelog.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.save", action: save)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    DDFieldContainer(labelKey: "cyclelog.start", helpKey: "cyclelog.start.help") {
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .tint(.ddSun)
                    }
                    endField
                    flowField
                    DDFieldContainer(labelKey: "cyclelog.notes", helpKey: "cyclelog.notes.help") {
                        TextField("cyclelog.notes.placeholder", text: $notes, axis: .vertical)
                            .font(.ddSans(16))
                            .foregroundColor(.ddPlumDeep)
                            .lineLimit(1...4)
                            .tint(.ddSun)
                    }
                    PrivacyNotice { Text("cyclelog.privacy") }
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
    }

    private var endField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $hasEndDate) {
                Text("cyclelog.end")
                    .font(.ddSans(14, .medium))
                    .foregroundColor(.ddFg2)
            }
            .tint(.ddSun)
            if hasEndDate {
                DDFieldContainer(labelKey: "cyclelog.end.date") {
                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .labelsHidden()
                        .tint(.ddSun)
                }
            }
        }
    }

    /// Builds a ``CycleDraft`` from the current form state and hands it to the
    /// parent to persist. The end date is included only when the user opted in.
    private func save() {
        onSave(
            CycleDraft(
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                flow: flow.rawValue.uppercased(),
                notes: notes
            )
        )
    }

    private var flowField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("cyclelog.flow")
                .font(.ddSans(14, .medium))
                .foregroundColor(.ddFg2)
            DDSegmented(
                segments: [
                    DDSegment(value: .spotting, label: "cyclelog.flow.spotting"),
                    DDSegment(value: .light, label: "cyclelog.flow.light"),
                    DDSegment(value: .medium, label: "cyclelog.flow.medium"),
                    DDSegment(value: .heavy, label: "cyclelog.flow.heavy")
                ],
                selection: $flow
            )
        }
    }
}
