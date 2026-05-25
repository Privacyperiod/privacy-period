// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The endometriosis screening questionnaire and its result, in one flow: a few
/// self-reported risk factors and 0–10 symptom sliders, then a screening risk
/// band computed on demand. It is a screening estimate — whether discussing
/// endometriosis with a clinician may be worth it — and never a diagnosis. Part of
/// the gated endometriosis feature (see `EndoFeature`).
struct EndoScreenView: View {
    let score: (EndoScreenDraft) -> EndoScreenResult
    let onClose: () -> Void

    @State private var familyHistory = false
    @State private var primaryInfertility = false
    @State private var bmiUnder22 = false
    @State private var cyclesUnder28 = false
    @State private var vasDysmenorrhea = 0
    @State private var vasDyspareunia = 0
    @State private var vasGi = 0
    @State private var vasUrinary = 0
    @State private var result: EndoScreenResult?

    private let vasMax = 10

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "endo.title") {
                DDNavButton(titleKey: "common.done", action: onClose)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    disclaimer
                    if let result {
                        resultSection(result)
                    } else {
                        form
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
            Text("endo.disclaimer")
                .font(.ddSans(13))
                .foregroundColor(.ddPlumDeep)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.08)))
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader("endo.section.factors")
            factorToggle("endo.factor.family", isOn: $familyHistory)
            factorToggle("endo.factor.infertility", isOn: $primaryInfertility)
            factorToggle("endo.factor.bmi", isOn: $bmiUnder22)
            factorToggle("endo.factor.cycle", isOn: $cyclesUnder28)
            sectionHeader("endo.section.symptoms")
            vasRow("endo.vas.dysmenorrhea", value: $vasDysmenorrhea)
            vasRow("endo.vas.dyspareunia", value: $vasDyspareunia)
            vasRow("endo.vas.gi", value: $vasGi)
            vasRow("endo.vas.urinary", value: $vasUrinary)
            DDPrimaryButton(titleKey: "endo.see_result") { result = score(draft()) }
                .padding(.top, 4)
        }
    }

    private func factorToggle(_ key: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(key).font(.ddSans(15)).foregroundColor(.ddPlumDeep)
        }
        .tint(.ddSun)
    }

    private func vasRow(_ key: LocalizedStringKey, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(key).font(.ddSans(15)).foregroundColor(.ddPlumDeep)
                Spacer()
                Text(verbatim: "\(value.wrappedValue)/\(vasMax)").font(.ddMono(13)).foregroundColor(.ddFg2)
            }
            Slider(
                value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0.rounded()) }),
                in: 0...Double(vasMax),
                step: 1
            )
            .tint(.ddSun)
        }
    }

    private func resultSection(_ result: EndoScreenResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(Self.headlineKey(result.extendedRisk))
                    .font(.ddDisplay(24))
                    .foregroundColor(.ddPlumDeep)
                    .fixedSize(horizontal: false, vertical: true)
                Text("endo.result.basis")
                    .font(.ddSans(14))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddLinenDeep.opacity(0.5)))

            ShareLink(item: EndoScreenReport.text(from: result)) {
                Text("endo.result.export")
                    .font(.ddSans(16, .semibold))
                    .foregroundColor(.ddLinen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddSun))
            }
            Button("endo.result.retake") { self.result = nil }
                .font(.ddSans(15, .medium))
                .foregroundColor(.ddSunDeep)
        }
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }

    private func draft() -> EndoScreenDraft {
        EndoScreenDraft(
            familyHistory: familyHistory,
            primaryInfertility: primaryInfertility,
            bmiUnder22: bmiUnder22,
            cyclesUnder28: cyclesUnder28,
            vasDysmenorrhea: vasDysmenorrhea,
            vasDeepDyspareunia: vasDyspareunia,
            vasGiSymptoms: vasGi,
            vasUrinarySymptoms: vasUrinary
        )
    }

    private static func headlineKey(_ risk: EndoRiskLevel) -> LocalizedStringKey {
        if risk == EndoRiskLevel.veryHigh || risk == EndoRiskLevel.high { return "endo.result.high" }
        if risk == EndoRiskLevel.intermediate { return "endo.result.intermediate" }
        return "endo.result.low"
    }
}
