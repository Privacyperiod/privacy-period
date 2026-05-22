// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Shared
import SwiftUI

/// Temporary bridge-verification screen.
///
/// It reads the on-device database schema version from the shared Kotlin
/// Multiplatform module, proving the Swift-to-Kotlin bridge links and runs at
/// runtime. This screen is replaced by the real onboarding and dashboard in
/// later milestones.
struct ContentView: View {
    /// Schema version reported by the shared module via ``PrivacyPeriodBridge``.
    private let schemaVersion = Int(PrivacyPeriodBridge.shared.databaseSchemaVersion())

    var body: some View {
        VStack(spacing: 12) {
            Text("app.name")
                .font(.title)
            Text("diagnostics.schema_version_label")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(verbatim: String(schemaVersion))
                .font(.footnote.monospaced())
        }
        .padding()
    }
}
