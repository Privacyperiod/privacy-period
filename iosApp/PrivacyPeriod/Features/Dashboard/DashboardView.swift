// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The home screen shown after onboarding: today's date, the current cycle day,
/// today's mood check-in (or a prompt to log it), and the quick-log actions.
/// Clinical-module entry points appear here only when their feature is un-gated.
struct DashboardView: View {
    @StateObject private var store = EncryptedStore()
    @State private var showingCycleLog = false
    @State private var showingMoodLog = false
    @State private var showingSettings = false
    @State private var showingCheckIn = false
    @State private var showingSummary = false
    @State private var showingEndoScreen = false
    @State private var showingFlowLog = false
    @State private var showingHmbSummary = false
    @State private var showingPmeCheckIn = false
    @State private var showingPmeSummary = false
    @State private var showingPmeEnroll = false
    @State private var pmeEnrolled = false
    // Set when the user taps the PME hint in the PMDD results; opens enrollment
    // once the results sheet has dismissed (avoids overlapping sheet presentation).
    @State private var pendingPmeEnroll = false
    @State private var showingGreene = false
    @State private var showingGreeneSummary = false
    @State private var summaryResult: CpassResult?
    @State private var pmeResult: PmePatternResult?
    @State private var hmbCycles: [HmbCycleScore]?
    @State private var greeneCompletions: [GreeneCompletionScore]?

    var body: some View {
        ZStack {
            Color.ddLinen.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    cycleCard
                    moodCard
                    DDPrimaryButton(titleKey: "dashboard.log_period") { showingCycleLog = true }
                        .padding(.top, 4)
                    clinicalEntries
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $showingCycleLog) {
            CycleLogView(
                onCancel: { showingCycleLog = false },
                onSave: { draft in
                    store.save(draft)
                    showingCycleLog = false
                }
            )
        }
        .sheet(isPresented: $showingMoodLog) {
            MoodLogView(
                initial: store.todayMoodEntry(),
                onCancel: { showingMoodLog = false },
                onSave: { draft in
                    store.saveMoodEntry(draft)
                    showingMoodLog = false
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                exportText: { store.exportData() },
                onDeleteAll: { store.deleteAllData() },
                onClose: { showingSettings = false }
            )
        }
        .sheet(isPresented: $showingCheckIn) {
            PmddCheckInView(
                onCancel: { showingCheckIn = false },
                onSave: { scores in
                    store.saveCheckIn(date: Date(), scores: scores)
                    showingCheckIn = false
                }
            )
        }
        .sheet(isPresented: $showingSummary, onDismiss: {
            if pendingPmeEnroll {
                pendingPmeEnroll = false
                showingPmeEnroll = true
            }
        }, content: {
            PmddResultsView(
                result: summaryResult,
                onExplorePme: (ClinicalGate.pme && !pmeEnrolled)
                    ? { pendingPmeEnroll = true; showingSummary = false }
                    : nil,
                onDone: { showingSummary = false }
            )
        })
        .sheet(isPresented: $showingPmeCheckIn) {
            PmeCheckInView(
                onCancel: { showingPmeCheckIn = false },
                onSave: { draft in
                    store.savePmeCheckIn(date: Date(), draft: draft)
                    showingPmeCheckIn = false
                }
            )
        }
        .sheet(isPresented: $showingEndoScreen) {
            EndoScreenView(score: { store.scoreEndoScreen($0) }, onClose: { showingEndoScreen = false })
        }
        .sheet(isPresented: $showingFlowLog) {
            FlowLogView(
                hasCycle: store.currentCycleId() != nil,
                onCancel: { showingFlowLog = false },
                onSave: { draft in
                    store.saveFlowEvent(draft)
                    showingFlowLog = false
                }
            )
        }
        .sheet(isPresented: $showingHmbSummary) {
            HmbResultsView(cycles: hmbCycles) { showingHmbSummary = false }
        }
        .sheet(isPresented: $showingPmeSummary) {
            PmeResultsView(result: pmeResult) { showingPmeSummary = false }
        }
        .sheet(isPresented: $showingPmeEnroll) {
            PmeEnrollmentView(
                onCancel: { showingPmeEnroll = false },
                onEnroll: { condition in
                    store.enrollPme(condition: condition)
                    pmeEnrolled = true
                    showingPmeEnroll = false
                }
            )
        }
        .sheet(isPresented: $showingGreene) {
            GreeneQuestionnaireView(
                onCancel: { showingGreene = false },
                onSave: { responses in
                    store.saveGreeneCompletion(responses)
                    showingGreene = false
                }
            )
        }
        .sheet(isPresented: $showingGreeneSummary) {
            GreeneResultsView(completions: greeneCompletions) { showingGreeneSummary = false }
        }
        .onAppear { pmeEnrolled = store.isPmeEnrolled }
    }
}

private extension DashboardView {
    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("dashboard.today")
                    .font(.ddSans(14, .medium))
                    .foregroundColor(.ddFg3)
                Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.ddDisplay(28))
                    .foregroundColor(.ddPlumDeep)
            }
            Spacer()
            Button { showingSettings = true } label: {
                DDIcon(name: "settings", size: 22).foregroundColor(.ddFg2)
            }
            .accessibilityLabel(Text("settings.entry"))
        }
    }

    var cycleCard: some View {
        card {
            if let snapshot = store.currentCycleSnapshot() {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: NSLocalizedString("dashboard.cycle.day", comment: "cycle day"),
                                snapshot.dayOfCycle))
                        .font(.ddDisplay(22))
                        .foregroundColor(.ddPlumDeep)
                    Text(String(format: NSLocalizedString("dashboard.cycle.since", comment: "period start"),
                                Self.displayDate(snapshot.startDate)))
                        .font(.ddSans(14))
                        .foregroundColor(.ddFg2)
                }
            } else {
                Text("dashboard.cycle.none")
                    .font(.ddSans(15))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var moodCard: some View {
        card {
            if let mood = store.todayMoodEntry() {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("dashboard.mood.today")
                            .font(.ddSans(13, .semibold))
                            .foregroundColor(.ddFg3)
                            .textCase(.uppercase)
                        Text(String(format: NSLocalizedString("dashboard.mood.summary", comment: "mood summary"),
                                    moodLabel(mood.mood), energyLabel(mood.energy)))
                            .font(.ddSans(15))
                            .foregroundColor(.ddPlumDeep)
                    }
                    Spacer()
                    Button("dashboard.mood.edit") { showingMoodLog = true }
                        .font(.ddSans(14, .medium))
                        .foregroundColor(.ddSun)
                }
            } else {
                HStack {
                    Text("dashboard.mood.prompt")
                        .font(.ddSans(15))
                        .foregroundColor(.ddFg2)
                    Spacer()
                    Button("mood.entry") { showingMoodLog = true }
                        .font(.ddSans(14, .medium))
                        .foregroundColor(.ddSun)
                }
            }
        }
    }

    @ViewBuilder var clinicalEntries: some View {
        if ClinicalGate.pmdd {
            Button("pmdd.checkin.title") { showingCheckIn = true }
                .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 4)
            Button("pmdd.results.title") {
                summaryResult = store.cpassResult()
                showingSummary = true
            }
            .font(.ddSans(15, .medium)).foregroundColor(.ddSun)
        }
        if ClinicalGate.endometriosis {
            Button("endo.entry") { showingEndoScreen = true }
                .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 4)
        }
        if ClinicalGate.hmb {
            Button("hmb.flow.entry") { showingFlowLog = true }
                .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 4)
            Button("hmb.results.entry") {
                hmbCycles = store.hmbCycleScores()
                showingHmbSummary = true
            }
            .font(.ddSans(15, .medium)).foregroundColor(.ddSun)
        }
        if ClinicalGate.pme {
            if pmeEnrolled {
                Button("pme.checkin.entry") { showingPmeCheckIn = true }
                    .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 4)
                Button("pme.results.entry") {
                    pmeResult = store.pmePattern()
                    showingPmeSummary = true
                }
                .font(.ddSans(15, .medium)).foregroundColor(.ddSun)
            } else {
                Button("pme.enroll.entry") { showingPmeEnroll = true }
                    .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 4)
            }
        }
        if ClinicalGate.perimenopause {
            Button("greene.entry") { showingGreene = true }
                .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 4)
            Button("greene.results.entry") {
                greeneCompletions = store.greeneCompletions()
                showingGreeneSummary = true
            }
            .font(.ddSans(15, .medium)).foregroundColor(.ddSun)
        }
    }

    func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddLinenDeep.opacity(0.5)))
    }

    func moodLabel(_ value: Int) -> String { NSLocalizedString("mood.mood.\(value)", comment: "mood level") }

    func energyLabel(_ value: Int) -> String { NSLocalizedString("mood.energy.\(value)", comment: "energy level") }

    static func displayDate(_ iso: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: iso) else { return iso }
        let out = DateFormatter()
        out.dateStyle = .medium
        return out.string(from: date)
    }
}
