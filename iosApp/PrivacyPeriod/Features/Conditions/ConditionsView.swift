// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The Conditions screen: the user chooses what they want to collect data on, to
/// share with a clinician. Selections drive what the home screen surfaces.
///
/// This is deliberately non-diagnostic (Principle 6): turning a condition on enables
/// *tracking*, never a diagnosis or a screening verdict. The premenstrual condition
/// asks one follow-up — whether the user already lives with a diagnosed underlying
/// condition — which decides DRSP-only (PMDD) vs DRSP + mood chart (PME).
struct ConditionsView: View {
    let store: EncryptedStore
    let onClose: () -> Void

    @State private var enabled: Set<String> = []
    @State private var premFamilies: Set<String> = []

    // Premenstrual follow-up options: self-reported existing diagnoses (selecting any
    // makes the module PME; selecting none keeps it PMDD-only). Multi-select, because
    // comorbidity is common. Order mirrors the PME enrollment flow.
    private let premenstrualFamilies = ["depression", "bipolar", "anxiety", "adhd", "other"]

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "conditions.title") {
                DDNavButton(titleKey: "common.done", action: onClose)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    if ConditionInfo.available.isEmpty {
                        emptyState
                    } else {
                        ForEach(ConditionInfo.available) { condition in
                            conditionRow(condition)
                            if condition.id == ConditionInfo.premenstrualId, enabled.contains(condition.id) {
                                premenstrualSubQuestion
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .onAppear(perform: load)
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: 10) {
            DDIcon(name: "shield-check", size: 18).foregroundColor(.ddPlumDeep)
            Text("conditions.intro")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private var emptyState: some View {
        Text("conditions.empty")
            .font(.ddSans(15))
            .foregroundColor(.ddFg2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
    }

    private func conditionRow(_ condition: ConditionInfo) -> some View {
        let isOn = enabled.contains(condition.id)
        return Button {
            toggle(condition)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isOn ? .ddSunDeep : .ddFg3)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(LocalizedStringKey(condition.nameKey))
                            .font(.ddSans(16, .medium))
                            .foregroundColor(.ddPlumDeep)
                        cadencePill(condition.cadenceKey)
                    }
                    Text(LocalizedStringKey(condition.blurbKey))
                        .font(.ddSans(13))
                        .foregroundColor(.ddFg3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinen))
            .overlay(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .stroke(isOn ? Color.ddSunDeep : Color.ddSand, lineWidth: isOn ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func cadencePill(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(.ddMono(10))
            .foregroundColor(.ddFg2)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.ddLinenDeep.opacity(0.7)))
    }

    private var premenstrualSubQuestion: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("conditions.premenstrual.underlying")
                .font(.ddSans(13, .medium))
                .foregroundColor(.ddFg2)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(premenstrualFamilies, id: \.self) { family in
                familyRow(family)
            }
        }
        .padding(.leading, 26)
        .padding(.bottom, 4)
    }

    private func familyRow(_ family: String) -> some View {
        let isSelected = premFamilies.contains(family)
        return Button {
            if isSelected { premFamilies.remove(family) } else { premFamilies.insert(family) }
            store.setPremenstrual(enabled: true, families: premFamilies)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .ddSunDeep : .ddFg3)
                Text(familyLabel(family))
                    .font(.ddSans(15, isSelected ? .medium : .regular))
                    .foregroundColor(.ddPlumDeep)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func familyLabel(_ family: String) -> String {
        NSLocalizedString("pme.condition.\(family)", comment: "premenstrual underlying-condition family")
    }

    private func toggle(_ condition: ConditionInfo) {
        if enabled.contains(condition.id) {
            enabled.remove(condition.id)
            persist(condition, on: false)
        } else {
            enabled.insert(condition.id)
            persist(condition, on: true)
        }
        // When prediction enrollment changes, recompute and reschedule any pending
        // period notification against the current cycle history.
        if condition.id == EncryptedStore.cyclePredictionModuleId {
            store.reschedulePeriodPredictionNotification()
        }
    }

    private func persist(_ condition: ConditionInfo, on: Bool) {
        guard condition.id == ConditionInfo.premenstrualId else {
            store.setEnrolled(moduleId: condition.id, on)
            return
        }
        if on {
            store.setPremenstrual(enabled: true, families: premFamilies)
        } else {
            premFamilies = []
            store.setPremenstrual(enabled: false, families: [])
        }
    }

    private func load() {
        var ids: Set<String> = []
        if store.isPremenstrualEnabled { ids.insert(ConditionInfo.premenstrualId) }
        for moduleId in ["hmb", "perimenopause", "endometriosis", "cycle_prediction"]
            where store.isEnrolled(moduleId: moduleId) {
            ids.insert(moduleId)
        }
        enabled = ids
        premFamilies = store.premenstrualFamilies()
    }
}
