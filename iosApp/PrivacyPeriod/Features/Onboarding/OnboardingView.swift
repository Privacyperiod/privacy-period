// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// First-run onboarding: the desert-dusk welcome hero, then an optional app-lock
/// step. Calls [onComplete] when the user finishes.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var step: Step = .welcome

    private enum Step {
        case welcome
        case lock
    }

    var body: some View {
        ZStack {
            Color.ddLinen.ignoresSafeArea()
            switch step {
            case .welcome:
                OnboardingWelcomeView { step = .lock }
            case .lock:
                OnboardingLockView(onContinue: onComplete)
            }
        }
    }
}

/// The welcome hero: sky + sun + mountains, then the name + logo lockup, a short
/// description, the privacy pills, and the single primary action.
private struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DesertHero()
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    PrivacyPeriodGlyph(size: 34)
                    Text("app.name")
                        .font(.ddDisplay(36))
                        .foregroundColor(.ddPlumDeep)
                }
                Text("onboarding.welcome.tagline")
                    .font(.ddSans(17))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("onboarding.welcome.note")
                    .font(.ddSans(13, .medium))
                    .foregroundColor(.ddFg2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                            .fill(Color.ddLinenDeep)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                            .stroke(Color.ddSand, lineWidth: 1)
                    )
                    .padding(.top, 2)
                Spacer(minLength: 16)
                DDPrimaryButton(titleKey: "onboarding.get_started", action: onNext)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }
}

/// The optional app-lock step. Enabling the lock is wired up in a later
/// milestone; for now the choice is recorded and Continue finishes onboarding.
private struct OnboardingLockView: View {
    let onContinue: () -> Void

    @State private var choice: LockChoice = .faceID

    private enum LockChoice {
        case faceID
        case pin
        case none
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("onboarding.lock.title")
                    .font(.ddDisplay(28))
                    .foregroundColor(.ddPlumDeep)
                Text("onboarding.lock.body")
                    .font(.ddSans(16))
                    .foregroundColor(.ddFg2)
                VStack(spacing: 8) {
                    option(
                        .faceID, icon: "fingerprint",
                        title: "onboarding.lock.faceid", detail: "onboarding.lock.faceid_detail"
                    )
                    option(
                        .pin, icon: "lock",
                        title: "onboarding.lock.pin", detail: "onboarding.lock.pin_detail"
                    )
                    option(
                        .none, icon: "eye",
                        title: "onboarding.lock.none", detail: "onboarding.lock.none_detail"
                    )
                }
                .padding(.top, 4)
            }
            Spacer()
            DDPrimaryButton(titleKey: "onboarding.continue", action: onContinue)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func option(
        _ value: LockChoice,
        icon: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        let selected = choice == value
        return Button {
            choice = value
        } label: {
            HStack(spacing: 14) {
                DDIcon(name: icon, size: 22).foregroundColor(.ddPlumDeep)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.ddSans(16, .semibold)).foregroundColor(.ddPlumDeep)
                    Text(detail).font(.ddSans(13)).foregroundColor(.ddFg2)
                }
                Spacer()
                if selected {
                    DDIcon(name: "check", size: 20).foregroundColor(.ddSunDeep)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .fill(selected ? Color.ddSun.opacity(0.10) : Color.ddLinen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DDRadius.md, style: .continuous)
                    .stroke(selected ? Color.ddSun : Color.ddSand, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
