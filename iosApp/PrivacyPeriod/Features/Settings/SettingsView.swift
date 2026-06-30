// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// The Settings screen: the user's control over their own data — export a copy,
/// and permanently delete everything. Reinforces the privacy model (on-device,
/// encrypted, no account) in plain language.
struct SettingsView: View {
    let exportText: () -> String
    let onDeleteAll: () -> Void
    /// Demo-only: replace the user's data with sample entries. Nil (hidden) outside
    /// demo builds.
    var onSeed: (() -> Void)?
    let onClose: () -> Void
    /// Called when the user changes period-prediction notification settings so that
    /// the next fire date can be recomputed against the current prediction.
    var onReschedulePeriodPrediction: (() -> Void)?

    @State private var showingDeleteConfirm = false
    @State private var deleted = false
    @State private var seeded = false
    @State private var showingCredits = false
    @State private var showingNotifications = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "settings.title") {
                DDNavButton(titleKey: "common.done", action: onClose)
            } trailing: {
                EmptyView()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    dataSection
                    remindersSection
                    privacySection
                    aboutSection
                    if let onSeed {
                        seedSection(onSeed)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
        .sheet(isPresented: $showingCredits) {
            CreditsView { showingCredits = false }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(
                onClose: { showingNotifications = false },
                onReschedulePeriodPrediction: onReschedulePeriodPrediction
            )
        }
        .alert("settings.delete.confirm.title", isPresented: $showingDeleteConfirm) {
            Button("common.cancel", role: .cancel) {}
            Button("settings.delete.confirm.action", role: .destructive) {
                onDeleteAll()
                deleted = true
            }
        } message: {
            Text("settings.delete.confirm.body")
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("settings.section.data")
            ShareLink(item: exportText()) {
                row(
                    icon: "trending-up",
                    titleKey: "settings.export",
                    helpKey: "settings.export.help",
                    tint: .ddPlumDeep
                )
            }
            .buttonStyle(.plain)
            if deleted {
                Text("settings.deleted")
                    .font(.ddSans(14, .medium))
                    .foregroundColor(.ddPlumDeep)
                    .padding(.top, 4)
            } else {
                Button { showingDeleteConfirm = true } label: {
                    row(
                        icon: "trending-up",
                        titleKey: "settings.delete",
                        helpKey: "settings.delete.help",
                        tint: .ddSunDeep
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("settings.section.reminders")
            Button { showingNotifications = true } label: {
                row(
                    icon: "bell",
                    titleKey: "settings.notifications",
                    helpKey: "settings.notifications.help",
                    tint: .ddPlumDeep
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("settings.section.privacy")
            HStack(alignment: .top, spacing: 10) {
                DDIcon(name: "lock", size: 18).foregroundColor(.ddPlumDeep)
                Text("settings.privacy.note")
                    .font(.ddSans(14))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.06)))
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("settings.section.about")
            // The repository is public so anyone can audit the privacy and
            // encryption claims — "the code is the privacy policy".
            if let repoURL = URL(string: "https://github.com/Privacyperiod/privacy-period") {
                Link(destination: repoURL) {
                    row(
                        icon: "eye",
                        titleKey: "settings.source",
                        helpKey: "settings.source.help",
                        tint: .ddPlumDeep
                    )
                }
                .buttonStyle(.plain)
            }
            Button { showingCredits = true } label: {
                row(
                    icon: "heart",
                    titleKey: "settings.credits",
                    helpKey: "settings.credits.help",
                    tint: .ddPlumDeep
                )
            }
            .buttonStyle(.plain)
            Text(String(format: NSLocalizedString("settings.version", comment: "app version"), appVersion))
                .font(.ddSans(14))
                .foregroundColor(.ddFg3)
        }
    }

    private func seedSection(_ onSeed: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("settings.section.demo")
            if seeded {
                Text("settings.seeded")
                    .font(.ddSans(14, .medium))
                    .foregroundColor(.ddPlumDeep)
            } else {
                Button { onSeed(); seeded = true } label: {
                    row(
                        icon: "trending-up",
                        titleKey: "settings.seed",
                        helpKey: "settings.seed.help",
                        tint: .ddPlumDeep
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(
        icon: String,
        titleKey: LocalizedStringKey,
        helpKey: LocalizedStringKey,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            DDIcon(name: icon, size: 18).foregroundColor(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey).font(.ddSans(16, .medium)).foregroundColor(tint)
                Text(helpKey).font(.ddSans(13)).foregroundColor(.ddFg3).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).fill(Color.ddLinen)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous).stroke(Color.ddSand, lineWidth: 1)
        )
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.ddSans(13, .semibold))
            .foregroundColor(.ddFg3)
            .textCase(.uppercase)
    }
}
