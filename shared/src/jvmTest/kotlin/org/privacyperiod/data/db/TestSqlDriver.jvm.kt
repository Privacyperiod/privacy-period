// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.data.db

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver

/**
 * JVM implementation of [createTestDriver] backed by an in-memory SQLite
 * database. The schema is created eagerly so the returned driver is ready to use.
 */
internal actual fun createTestDriver(): SqlDriver =
    JdbcSqliteDriver(JdbcSqliteDriver.IN_MEMORY).also { driver ->
        PrivacyPeriodDatabase.Schema.create(driver)
    }
