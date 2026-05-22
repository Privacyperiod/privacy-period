// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.shared

import org.privacyperiod.data.db.PrivacyPeriodDatabase

/**
 * A small, stable surface exposed to the native apps.
 *
 * It exists so the Swift (and later Kotlin/Compose) UI layers have a predictable
 * entry point into the shared module, and so the Swift-to-Kotlin bridge can be
 * verified end to end. It performs no I/O and holds no state.
 */
object PrivacyPeriodBridge {
    /**
     * The version of the on-device database schema.
     *
     * Surfaced for diagnostics (for example, a future About screen) and used to
     * confirm the shared module is correctly linked into the host app.
     *
     * @return The current [PrivacyPeriodDatabase] schema version.
     */
    fun databaseSchemaVersion(): Int = PrivacyPeriodDatabase.Schema.version.toInt()
}
