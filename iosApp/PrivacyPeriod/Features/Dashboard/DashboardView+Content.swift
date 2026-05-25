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

    // The landing-page hero. When a premenstrual condition is tracked it shows the
    // Mental + Physical Daily Data time series with a compact "toward a clinician
    // review" readiness footer — one tracker, not two. When it isn't, it reverts to
    // the plain period-cycle context.
    var cycleCard: some View {
        card {
            if let snapshot = store.currentCycleSnapshot() {
                VStack(alignment: .leading, spacing: 12) {
                    cycleHeader(snapshot)
                    if isPremenstrualTracked {
                        dailyDataTracker
                    }
                }
            } else {
                Text("dashboard.cycle.none")
                    .font(.ddSans(15))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var isPremenstrualTracked: Bool {
        enrolled.contains(EncryptedStore.pmddModuleId) || enrolled.contains(EncryptedStore.pmeModuleId)
    }

    private func cycleHeader(_ snapshot: CycleSnapshot) -> some View {
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
    }

    // The Mental + Physical Daily Data tracker: a time series of daily aggregate
    // scores plus a compact readiness footer toward the two cycles a clinician needs.
    @ViewBuilder var dailyDataTracker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("pme.checkin.entry")
                .font(.ddSans(13, .semibold))
                .foregroundColor(.ddFg3)
                .textCase(.uppercase)
            if let series = store.dailyAggregateSeries(), !series.bars.isEmpty {
                CycleRevealChart(series: series)
            } else {
                Text("reveal.empty")
                    .font(.ddSans(14))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            readinessFooter
        }
    }

    // Progress toward a clinician-ready analysis (C-PASS needs two scored cycles):
    // a pip per scored cycle and a short status. A clinical capability unlocking,
    // stated factually — never a streak.
    @ViewBuilder var readinessFooter: some View {
        if let readiness = store.premenstrualReadiness() {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(0..<readiness.requiredCycles, id: \.self) { index in
                        Circle()
                            .fill(index < readiness.scoredCycles ? Color.ddSun : Color.ddSand)
                            .frame(width: 9, height: 9)
                    }
                }
                Group {
                    if readiness.isReady {
                        Text("readiness.ready.short")
                    } else {
                        Text(verbatim: String(
                            format: NSLocalizedString("readiness.progress", comment: "cycles tracked"),
                            readiness.scoredCycles, readiness.requiredCycles
                        ))
                    }
                }
                .font(.ddSans(13, .medium))
                .foregroundColor(.ddPlumDeep)
                Spacer(minLength: 0)
            }
        }
    }

    // The daily premenstrual log ("Mental + Physical Daily Data"), raised to a
    // prominent top-level action like "Log period" because it is the main daily task.
    // Routes to the PME mood-chart check-in when an underlying condition is recorded,
    // otherwise the DRSP-only check-in.
    @ViewBuilder var dailyCheckInButton: some View {
        if enrolled.contains(EncryptedStore.pmeModuleId) {
            DDPrimaryButton(titleKey: "pme.checkin.entry") { showingPmeCheckIn = true }
                .padding(.top, 4)
        } else if enrolled.contains(EncryptedStore.pmddModuleId) {
            DDPrimaryButton(titleKey: "pme.checkin.entry") { showingCheckIn = true }
                .padding(.top, 4)
        }
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
        // Always shown: it holds the always-available Quick Daily Check-in plus any
        // enrolled tracking tasks.
        DDCollapsibleSection(titleKey: "home.section.tracking") { trackingRows }
            .padding(.top, 8)
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

    // The ongoing tracking tasks (cadence-tagged logging actions) and the result
    // views, grouped under the Tracking section. Leads with the always-available
    // Quick Daily Check-in (mood & energy); the daily premenstrual log itself is a
    // top-level button (`dailyCheckInButton`), not repeated here.
    @ViewBuilder var trackingRows: some View {
        trackingLink("tracking.quick_checkin") { showingMoodLog = true }
        // The heavy bleeding tracker is reached from the "Log period" screen (it logs
        // events against a cycle), not listed here.
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
