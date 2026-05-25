// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The MAC-PMSS daily check-in for the PME module: the DRSP premenstrual items
/// plus the MAC-PMSS mood chart, same-day only.
///
/// The mood chart includes a suicidal-ideation item handled with care — it offers
/// "prefer not to answer" (which still counts as answered), keeps a discreet
/// support-resources link always available, and gently surfaces crisis resources
/// when the rating is elevated. The module stays gated until clinical/safety
/// sign-off; nothing here is a diagnosis.
struct PmeCheckInView: View {
    let onCancel: () -> Void
    let onSave: (PmeCheckInDraft) -> Void

    @State private var drsp: [Int: Int] = [:]
    @State private var mood: [String: Int] = [:]
    @State private var siRating: Int?
    @State private var siAbstained = false
    @State private var definitionTarget: DefinitionTarget?

    /// An item the user tapped to see its definition. `symptomId` selects the
    /// (licensed) official definition; `nameKey` is the on-screen item label.
    private struct DefinitionTarget: Identifiable {
        let symptomId: String
        let nameKey: String
        var id: String { symptomId }
    }

    private let today = Date()
    private let emotionalItems = Array(1...8)
    private let physicalItems = Array(9...21)
    private let impactItems = Array(22...24)
    // Mood captured as two poles (depressed + elevated) because MAC-PMSS targets
    // premenstrual exacerbation of mood disorders, bipolar included. Each item is a
    // single-direction severity construct, so the shared rating control reads
    // coherently. Order mirrors the catalog.
    private let moodItems = [
        "macpmss_depressed_mood",
        "macpmss_mood_elevation",
        "macpmss_anxiety",
        "macpmss_low_energy",
        "macpmss_functional_impairment"
    ]
    private let siItem = "macpmss_suicidal_ideation"

    // A rating at or above this gently surfaces crisis resources (non-blocking).
    private let siEscalationThreshold = 4
    private let moodScaleMax = 5

    private var allDrsp: [Int] { emotionalItems + physicalItems + impactItems }
    private var isComplete: Bool {
        allDrsp.allSatisfy { drsp[$0] != nil } &&
            moodItems.allSatisfy { mood[$0] != nil } &&
            (siRating != nil || siAbstained)
    }

    private var siElevated: Bool { (siRating ?? 0) >= siEscalationThreshold }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "pme.checkin.title") {
                DDNavButton(titleKey: "common.cancel", action: onCancel)
            } trailing: {
                DDNavButton(titleKey: "common.save", isEnabled: isComplete) { onSave(draft()) }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    disclaimer
                    header
                    drspSection(titleKey: "pmdd.section.emotional", items: emotionalItems)
                    drspSection(titleKey: "pmdd.section.physical", items: physicalItems)
                    drspSection(titleKey: "pmdd.section.impact", items: impactItems)
                    moodSection
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .sheet(item: $definitionTarget) { target in
            SymptomDefinitionSheet(
                symptomId: target.symptomId,
                nameKey: target.nameKey,
                onClose: { definitionTarget = nil }
            )
        }
    }

    /// A tappable item label that opens the definition sheet. Used for every
    /// screening item so a clinician (or user) can read what an item means.
    private func definitionTitle(_ nameKey: String, symptomId: String) -> some View {
        Button {
            definitionTarget = DefinitionTarget(symptomId: symptomId, nameKey: nameKey)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(NSLocalizedString(nameKey, comment: "screening item name"))
                    .font(.ddSans(15))
                    .foregroundColor(.ddPlumDeep)
                    .multilineTextAlignment(.leading)
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.ddFg3)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("definition.hint"))
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            DDIcon(name: "shield-check", size: 18).foregroundColor(.ddPlumDeep)
            Text("pme.checkin.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("pmdd.checkin.today")
                .font(.ddSans(13, .medium))
                .foregroundColor(.ddFg3)
            Text(today, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.ddDisplay(26))
                .foregroundColor(.ddPlumDeep)
            Text("pme.checkin.intro")
                .font(.ddSans(14))
                .foregroundColor(.ddFg2)
                .padding(.top, 2)
        }
    }

    private func drspSection(titleKey: LocalizedStringKey, items: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(titleKey)
            ForEach(items, id: \.self) { item in
                drspRow(item)
            }
        }
    }

    private func drspRow(_ item: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            definitionTitle("pmdd.item.\(item)", symptomId: "drsp_\(item)")
            DDLikert(selection: drspBinding(item))
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader("pme.section.mood")
            ForEach(moodItems, id: \.self) { item in
                moodRow(item)
            }
            suicidalIdeationRow
        }
    }

    private func moodRow(_ item: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            definitionTitle("symptom.\(item)", symptomId: item)
            DDLikert(
                selection: moodBinding(item),
                range: 1...moodScaleMax,
                labelKeyPrefix: anchorPrefix(item)
            )
        }
    }

    // Most mood items use the standard severity anchors; functional impairment
    // reads as none → unable, so it gets its own anchor set.
    private func anchorPrefix(_ item: String) -> String {
        item == "macpmss_functional_impairment" ? "pme.impairment." : "pmdd.level."
    }

    private var suicidalIdeationRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            definitionTitle("symptom.\(siItem)", symptomId: siItem)
            DDLikert(selection: siBinding, range: 1...moodScaleMax)
            Button("pmdd.si.prefer_not") {
                siRating = nil
                siAbstained = true
            }
            .font(.ddSans(13, .medium))
            .foregroundColor(siAbstained ? .ddPlumDeep : .ddFg3)
            // Always present; becomes prominent (the gentle escalation) when the
            // rating is elevated. One instance — a same-type if/else here breaks
            // SwiftUI's view graph.
            SupportResourcesView(prominent: siElevated)
        }
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }

    private func drspBinding(_ item: Int) -> Binding<Int?> {
        Binding(get: { drsp[item] }, set: { drsp[item] = $0 })
    }

    private func moodBinding(_ item: String) -> Binding<Int?> {
        Binding(get: { mood[item] }, set: { mood[item] = $0 })
    }

    private var siBinding: Binding<Int?> {
        Binding(get: { siRating }, set: { siRating = $0; siAbstained = false })
    }

    private func draft() -> PmeCheckInDraft {
        PmeCheckInDraft(drsp: drsp, mood: mood, siRating: siRating, siAbstained: siAbstained)
    }
}

/// The values collected by the PME check-in, handed to the parent to persist.
struct PmeCheckInDraft {
    let drsp: [Int: Int]
    let mood: [String: Int]
    /// The suicidal-ideation rating, or nil when not rated.
    let siRating: Int?
    /// True when the user explicitly chose "prefer not to answer" for SI.
    let siAbstained: Bool
}
