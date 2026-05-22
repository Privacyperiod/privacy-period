// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.data.db

import app.cash.sqldelight.db.SqlDriver

/**
 * Creates an in-memory [SqlDriver] with the [PrivacyPeriodDatabase] schema
 * already applied, for use in unit tests.
 *
 * Each platform supplies its own implementation: an in-memory SQLite JDBC driver
 * on the JVM and an in-memory native SQLite driver on iOS. The database exists
 * only for the lifetime of the test and is never written to disk, so tests touch
 * no real user data.
 *
 * @return A ready-to-use driver backed by a fresh, empty database.
 */
internal expect fun createTestDriver(): SqlDriver
