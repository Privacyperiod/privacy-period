// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

// Home-screen content builders and derived state for DashboardView, split out
// to keep the main view file focused on the view body and its sheets.
extension DashboardView {
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
    // period") because it is the main daily task. Named for the condition and given a
    // purpose line so it reads distinctly from the quick "Mood & energy" wellbeing
    // pulse. Routes to the PME mood-chart check-in when an underlying condition is
    // recorded, otherwise the DRSP-only check-in.
    @ViewBuilder var dailyCheckInButton: some View {
        if enrolled.contains(EncryptedStore.pmeModuleId) {
            premenstrualCheckInButton { showingPmeCheckIn = true }
        } else if enrolled.contains(EncryptedStore.pmddModuleId) {
            premenstrualCheckInButton { showingCheckIn = true }
        }
    }

    func premenstrualCheckInButton(action: @escaping () -> Void) -> some View {
        VStack(spacing: 5) {
            DDPrimaryButton(titleKey: "pme.checkin.entry", action: action)
            Text("checkin.premenstrual.subtitle")
                .font(.ddSans(12))
                .foregroundColor(.ddFg3)
        }
        .padding(.top, 4)
    }

    // Periodic tasks that are currently due, promoted to a prominent button under
    // "Log period" until completed for their period. The perimenopause check-in is
    // monthly; once answered this month the button disappears until next month.
    @ViewBuilder var monthlyTasks: some View {
        if enrolled.contains("perimenopause"), greeneDueThisMonth {
            monthlyTaskButton(
                titleKey: "greene.entry",
                subtitleKey: "checkin.perimenopause.subtitle"
            ) { showingGreene = true }
                .padding(.top, 4)
        }
    }

    func monthlyTaskButton(
        titleKey: LocalizedStringKey,
        subtitleKey: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                DDIcon(name: "calendar", size: 18).foregroundColor(.ddSun)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleKey).font(.ddSans(16, .semibold)).foregroundColor(.ddSun)
                    Text(subtitleKey).font(.ddSans(12)).foregroundColor(.ddFg3)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .strokeBorder(Color.ddSun, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // Refreshes the derived home state: which conditions are enrolled, and whether the
    // monthly perimenopause questionnaire is still due this month.
    func refreshState() {
        enrolled = store.enabledModuleIds()
        greeneDueThisMonth = enrolled.contains("perimenopause")
            && !store.instrumentCompletedThisMonth("greene_climacteric")
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
        // Only list the questionnaire here when it isn't already promoted as the
        // monthly button above, so "Perimenopause check-in" never appears twice.
        if enrolled.contains("perimenopause"), !greeneDueThisMonth {
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
            refreshState()
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
