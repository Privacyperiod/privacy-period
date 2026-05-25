// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import SwiftUI

/// A tap-to-define sheet for a single screening item.
///
/// Shows the item's name and its source instrument, then either the official,
/// licensed definition (when the licensed asset is bundled) or a neutral state
/// explaining that the official definition appears once the instrument is
/// licensed. It never shows invented or paraphrased clinical wording.
struct SymptomDefinitionSheet: View {
    let symptomId: String
    let nameKey: String
    let onClose: () -> Void

    private var definition: InstrumentDefinitions.Definition? {
        InstrumentDefinitions.definition(for: symptomId)
    }

    private var instrument: InstrumentDefinitions.Instrument {
        definition?.instrument ?? InstrumentDefinitions.instrument(for: symptomId)
    }

    var body: some View {
        VStack(spacing: 0) {
            DDNav(titleKey: "definition.title") {
                EmptyView()
            } trailing: {
                DDNavButton(titleKey: "common.done", action: onClose)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString(nameKey, comment: "screening item name"))
                        .font(.ddDisplay(26))
                        .foregroundColor(.ddPlumDeep)
                    sourceChip
                    if let definition {
                        Text(definition.text)
                            .font(.ddSans(15))
                            .foregroundColor(.ddFg2)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        neutralState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .background(Color.ddLinen.ignoresSafeArea())
    }

    private var sourceChip: some View {
        Text(String(format: NSLocalizedString("definition.source", comment: "instrument provenance"),
                    instrument.rawValue))
            .font(.ddSans(12, .semibold))
            .foregroundColor(.ddPlumDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.ddPlumDeep.opacity(0.08)))
    }

    // Shown in the open-source build, where the licensed instrument text is not
    // bundled. Factual; never a substitute clinical definition.
    private var neutralState: some View {
        HStack(alignment: .top, spacing: 10) {
            DDIcon(name: "shield-check", size: 18).foregroundColor(.ddPlumDeep)
            Text("definition.pending")
                .font(.ddSans(14))
                .foregroundColor(.ddFg2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DDRadius.lg).fill(Color.ddPlumDeep.opacity(0.06)))
    }
}
