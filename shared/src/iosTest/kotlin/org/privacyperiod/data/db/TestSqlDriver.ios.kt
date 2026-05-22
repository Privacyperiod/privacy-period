// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.data.db

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.inMemoryDriver

/**
 * iOS implementation of [createTestDriver] backed by an in-memory native SQLite
 * database. [inMemoryDriver] applies the schema as part of construction.
 */
internal actual fun createTestDriver(): SqlDriver = inMemoryDriver(PrivacyPeriodDatabase.Schema)
