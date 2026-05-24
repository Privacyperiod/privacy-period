// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.clinical

/**
 * Minimal ISO-8601 calendar-date arithmetic for the clinical layer, with no
 * external dependency.
 *
 * Stored dates are plain `YYYY-MM-DD` strings. Modules need day differences (a
 * symptom's date relative to a menses onset), so this converts a calendar date to
 * an epoch day — the count of whole days since 1970-01-01. Working in calendar
 * days keeps the math free of time zones and daylight saving.
 */
object IsoDate {
    /**
     * Parses `YYYY-MM-DD` to an epoch day, or null if it is not a valid date.
     *
     * Guard clauses validate the three date parts; the literals are calendar bounds.
     */
    @Suppress("ReturnCount", "MagicNumber")
    fun toEpochDay(iso: String): Int? {
        val parts = iso.split("-")
        if (parts.size != 3) return null
        val year = parts[0].toIntOrNull() ?: return null
        val month = parts[1].toIntOrNull() ?: return null
        val day = parts[2].toIntOrNull() ?: return null
        if (month !in 1..12 || day !in 1..31) return null
        return daysFromCivil(year, month, day)
    }

    /** Formats an epoch day back to a `YYYY-MM-DD` string. */
    fun fromEpochDay(epochDay: Int): String {
        val (year, month, day) = civilFromDays(epochDay)
        val mm = month.toString().padStart(2, '0')
        val dd = day.toString().padStart(2, '0')
        return "$year-$mm-$dd"
    }

    // Howard Hinnant's days_from_civil algorithm. The constants are intrinsic to
    // the proleptic Gregorian calendar arithmetic, not arbitrary magic numbers.
    @Suppress("MagicNumber")
    private fun daysFromCivil(year: Int, month: Int, day: Int): Int {
        val y = if (month <= 2) year - 1 else year
        val era = (if (y >= 0) y else y - 399) / 400
        val yearOfEra = y - era * 400
        val dayOfYear = (153 * (if (month > 2) month - 3 else month + 9) + 2) / 5 + day - 1
        val dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097 + dayOfEra - 719468
    }

    // The inverse, Hinnant's civil_from_days. Returns (year, month, day).
    @Suppress("MagicNumber")
    private fun civilFromDays(epochDay: Int): Triple<Int, Int, Int> {
        val z = epochDay + 719468
        val era = (if (z >= 0) z else z - 146096) / 146097
        val dayOfEra = z - era * 146097
        val yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365
        val year = yearOfEra + era * 400
        val dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        val mp = (5 * dayOfYear + 2) / 153
        val day = dayOfYear - (153 * mp + 2) / 5 + 1
        val month = if (mp < 10) mp + 3 else mp - 9
        return Triple(if (month <= 2) year + 1 else year, month, day)
    }
}
