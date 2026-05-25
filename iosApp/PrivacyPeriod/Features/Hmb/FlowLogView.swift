// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// Logs a single menstrual-flow event for PBAC heavy-bleeding tracking: a product
/// change at a saturation, a clot, a flooding episode, or a directly-measured
/// volume (cups/discs). Each save records one event against the current cycle.
///
/// Part of the gated Heavy Menstrual Bleeding feature (see `HmbFeature`). Nothing
/// here is a diagnosis.
struct FlowLogView: View {
    let hasCycle: Bool
    let onCancel: () -> Void
    let onSave: (FlowEventDraft) -> Void
    /// Saves the current event without closing, so several events can be logged in a
    /// row (PBAC is per-event — many product changes, clots, or floods across a day).
    var onSaveAnother: ((FlowEventDraft) -> Void)?

    @State private var kind = "pad"
    @State private var saturation = "moderate"
    @State private var clotSize = "small"
    @State private var measuredMl = 30
    /// How many events have been saved without leaving this screen (for the running
    /// "logged so far" confirmation).
    @State private var loggedCount = 0

    private let kinds = ["pad", "tampon", "period_underwear", "cup", "disc", "clot", "flooding"]
    private let productKinds = ["pad", "tampon", "period_underwear"]
    private let measuredKinds = ["cup", "disc"]

    private let mlStep = 5
    private let mlMax = 120

    // NSLocalizedString resolves the dynamic key to its value; a LocalizedStringKey
    // built from a runtime String does not auto-localize, so resolve it first.
    private var saturationSegments: [DDSegment<String>] {
        ["light", "moderate", "heavy", "soaked"].map {
            DDSegment(value: $0, label: LocalizedStringKey(NSLocalizedString("hmb.sat.\($0)", comment: "saturation")))
        }
    }

    private var clotSegments: [DDSegment<String>] {
        ["small", "large"].map {
            DDSegment(value: $0, label: LocalizedStringKey(NSLocalizedString("hmb.clot.\($0)", comment: "clot size")))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "hmb.flow.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.save", isEnabled: hasCycle) { onSave(draft()) }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    disclaimer
                    if !hasCycle {
                        noCycleNotice
                    }
                    sectionHeader("hmb.flow.kind")
                    VStack(spacing: 10) {
                        ForEach(kinds, id: \.self) { kindRow($0) }
                    }
                    detailSection
                    if onSaveAnother != nil {
                        addAnotherButton
                    }
                    if loggedCount > 0 {
                        Text(String(format: NSLocalizedString("hmb.flow.logged", comment: "events logged so far"),
                                    loggedCount))
                            .font(.ddSans(13, .medium))
                            .foregroundColor(.ddPlumDeep)
                            .frame(maxWidth: .infinity)
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
            Text("hmb.flow.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private var noCycleNotice: some View {
        Text("hmb.flow.nocycle")
            .font(.ddSans(14))
            .foregroundColor(.ddFg2)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var detailSection: some View {
        if productKinds.contains(kind) {
            sectionHeader("hmb.flow.saturation")
            DDSegmented(segments: saturationSegments, selection: $saturation)
        } else if measuredKinds.contains(kind) {
            sectionHeader("hmb.flow.measured")
            Stepper(value: $measuredMl, in: 0...mlMax, step: mlStep) {
                Text(verbatim: "\(measuredMl) mL")
                    .font(.ddSans(16, .medium))
                    .foregroundColor(.ddPlumDeep)
            }
        } else if kind == "clot" {
            sectionHeader("hmb.flow.clotsize")
            DDSegmented(segments: clotSegments, selection: $clotSize)
        }
    }

    private func kindRow(_ value: String) -> some View {
        let isSelected = kind == value
        return Button {
            kind = value
        } label: {
            HStack {
                Text(NSLocalizedString("hmb.flow.\(value)", comment: "flow type"))
                    .font(.ddSans(16, isSelected ? .semibold : .regular))
                    .foregroundColor(.ddPlumDeep)
                Spacer()
                if isSelected {
                    DDIcon(name: "check", size: 18).foregroundColor(.ddSunDeep)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }

    private var addAnotherButton: some View {
        Button { logAnother() } label: {
            Text("hmb.flow.add_another")
                .font(.ddSans(16, .semibold))
                .foregroundColor(.ddSun)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                        .strokeBorder(Color.ddSun, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(!hasCycle)
    }

    // Saves the current event and resets the form to log the next one, without leaving.
    private func logAnother() {
        onSaveAnother?(draft())
        loggedCount += 1
        kind = "pad"
        saturation = "moderate"
        clotSize = "small"
        measuredMl = 30
    }

    private func draft() -> FlowEventDraft {
        switch kind {
        case "pad", "tampon", "period_underwear":
            return FlowEventDraft(flowType: kind, saturation: saturation, clotSize: nil, measuredMl: nil)
        case "cup", "disc":
            return FlowEventDraft(flowType: kind, saturation: nil, clotSize: nil, measuredMl: Double(measuredMl))
        case "clot":
            return FlowEventDraft(flowType: "clot", saturation: nil, clotSize: clotSize, measuredMl: nil)
        default:
            return FlowEventDraft(flowType: "flooding", saturation: nil, clotSize: nil, measuredMl: nil)
        }
    }
}
