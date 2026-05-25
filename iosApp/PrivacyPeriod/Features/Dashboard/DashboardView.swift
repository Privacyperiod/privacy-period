// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The home screen shown after onboarding: today's date, the current cycle day,
/// today's mood check-in (or a prompt to log it), and the quick-log actions.
/// Clinical-module entry points appear here only when their feature is un-gated.
struct DashboardView: View {
    @ObservedObject var store: EncryptedStore
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
    @State private var showingConditions = false
    // The set of enrolled module ids; drives which clinical entries appear. Refreshed
    // on appear and whenever the Conditions sheet closes.
    @State private var enrolled: Set<String> = []
    // Set when the user taps the "add an underlying condition" hint in the PMDD
    // results; opens the Conditions sheet once the results sheet has dismissed
    // (avoids overlapping sheet presentation).
    @State private var pendingConditions = false
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
                    dailyCheckInButton
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
                onSeed: seedAction,
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
            if pendingConditions {
                pendingConditions = false
                showingConditions = true
            }
        }, content: {
            PmddResultsView(
                result: summaryResult,
                onExplorePme: enrolled.contains(EncryptedStore.pmddModuleId)
                    ? { pendingConditions = true; showingSummary = false }
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
        .sheet(isPresented: $showingConditions, onDismiss: { enrolled = store.enabledModuleIds() }, content: {
            ConditionsView(store: store, onClose: { showingConditions = false })
        })
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
        .onAppear { enrolled = store.enabledModuleIds() }
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

    // The daily premenstrual log, raised to a prominent top-level action (like "Log
    // period") because it is the main daily task: the PME mood & symptom check-in when
    // a underlying condition is recorded, otherwise the DRSP daily check-in.
    @ViewBuilder var dailyCheckInButton: some View {
        if enrolled.contains(EncryptedStore.pmeModuleId) {
            DDPrimaryButton(titleKey: "pme.checkin.entry") { showingPmeCheckIn = true }
                .padding(.top, 4)
        } else if enrolled.contains(EncryptedStore.pmddModuleId) {
            DDPrimaryButton(titleKey: "pmdd.checkin.title") { showingCheckIn = true }
                .padding(.top, 4)
        }
    }

    @ViewBuilder var clinicalEntries: some View {
        if hasTrackingEntries {
            DDCollapsibleSection(titleKey: "home.section.tracking") { trackingRows }
                .padding(.top, 8)
        }
        if enrolled.contains("endometriosis") {
            DDCollapsibleSection(titleKey: "home.section.screening") {
                trackingLink("endo.entry", cadenceKey: "condition.cadence.occasional") {
                    showingEndoScreen = true
                }
            }
            .padding(.top, 4)
        }
        // The doorway to choosing what you collect data on; drives everything above.
        Button("conditions.entry") { showingConditions = true }
            .font(.ddSans(15, .medium)).foregroundColor(.ddSun).padding(.top, 12)
    }

    var hasTrackingEntries: Bool {
        enrolled.contains(EncryptedStore.pmddModuleId)
            || enrolled.contains(EncryptedStore.pmeModuleId)
            || enrolled.contains("hmb")
            || enrolled.contains("perimenopause")
    }

    // The ongoing tracking tasks (cadence-tagged logging actions) and the result
    // views, grouped under the Tracking section. The daily premenstrual log itself is
    // a top-level button (`dailyCheckInButton`), not repeated here.
    @ViewBuilder var trackingRows: some View {
        if enrolled.contains("hmb") {
            trackingLink("hmb.flow.entry", cadenceKey: "condition.cadence.perevent") {
                showingFlowLog = true
            }
        }
        if enrolled.contains("perimenopause") {
            trackingLink("greene.entry", cadenceKey: "condition.cadence.monthly") {
                showingGreene = true
            }
        }
        if enrolled.contains(EncryptedStore.pmeModuleId) {
            trackingLink("pme.results.entry") {
                pmeResult = store.pmePattern()
                showingPmeSummary = true
            }
        } else if enrolled.contains(EncryptedStore.pmddModuleId) {
            trackingLink("pmdd.results.title") {
                summaryResult = store.cpassResult()
                showingSummary = true
            }
        }
        if enrolled.contains("hmb") {
            trackingLink("hmb.results.entry") {
                hmbCycles = store.hmbCycleScores()
                showingHmbSummary = true
            }
        }
        if enrolled.contains("perimenopause") {
            trackingLink("greene.results.entry") {
                greeneCompletions = store.greeneCompletions()
                showingGreeneSummary = true
            }
        }
    }

    func trackingLink(
        _ titleKey: LocalizedStringKey,
        cadenceKey: LocalizedStringKey? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(titleKey).font(.ddSans(15, .medium)).foregroundColor(.ddSun)
                Spacer(minLength: 0)
                if let cadenceKey {
                    Text(cadenceKey)
                        .font(.ddMono(10))
                        .foregroundColor(.ddFg2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.ddLinenDeep.opacity(0.7)))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // Demo-only sample-data action; nil (so the Settings button hides) otherwise.
    var seedAction: (() -> Void)? {
        #if DEMO
        return {
            store.seedSampleData()
            enrolled = store.enabledModuleIds()
        }
        #else
        return nil
        #endif
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
