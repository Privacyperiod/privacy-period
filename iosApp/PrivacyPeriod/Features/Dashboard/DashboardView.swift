// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// The home screen shown after onboarding: today's date, the current cycle day,
/// today's mood check-in (or a prompt to log it), and the quick-log actions.
/// Clinical-module entry points appear here only when their feature is un-gated.
struct DashboardView: View {
    @ObservedObject var store: EncryptedStore
    @State var showingCycleLog = false
    @State var showingMoodLog = false
    @State var showingSettings = false
    @State var showingCheckIn = false
    @State var showingSummary = false
    @State var showingEndoScreen = false
    @State var showingFlowLog = false
    @State var showingHmbSummary = false
    @State var showingPmeCheckIn = false
    @State var showingPmeSummary = false
    @State var showingConditions = false
    // The set of enrolled module ids; drives which clinical entries appear. Refreshed
    // on appear and whenever the Conditions sheet closes.
    @State var enrolled: Set<String> = []
    // Set when the user taps the "add an underlying condition" hint in the PMDD
    // results; opens the Conditions sheet once the results sheet has dismissed
    // (avoids overlapping sheet presentation).
    @State var pendingConditions = false
    @State var showingGreene = false
    @State var showingGreeneSummary = false
    // Whether the monthly perimenopause questionnaire is still due this month; when
    // true it is promoted to a button under "Log period" until completed for the month.
    @State var greeneDueThisMonth = false
    @State var summaryResult: CpassResult?
    @State var pmeResult: PmePatternResult?
    @State var hmbCycles: [HmbCycleScore]?
    @State var greeneCompletions: [GreeneCompletionScore]?

    var body: some View {
        ZStack {
            Color.ddLinen.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    cycleCard
                    dailyCheckInButton
                    DDPrimaryButton(titleKey: "dashboard.log_period") { showingCycleLog = true }
                        .padding(.top, 4)
                    monthlyTasks
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
        .sheet(isPresented: $showingConditions, onDismiss: { refreshState() }, content: {
            ConditionsView(store: store, onClose: { showingConditions = false })
        })
        .sheet(isPresented: $showingGreene) {
            GreeneQuestionnaireView(
                onCancel: { showingGreene = false },
                onSave: { responses in
                    store.saveGreeneCompletion(responses)
                    showingGreene = false
                    refreshState()
                }
            )
        }
        .sheet(isPresented: $showingGreeneSummary) {
            GreeneResultsView(completions: greeneCompletions) { showingGreeneSummary = false }
        }
        .onAppear { refreshState() }
    }
}
