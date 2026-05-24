// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

/**
 * A single DRSP rating tagged with the calendar day it was recorded on, expressed
 * as an epoch day (whole days since 1970-01-01).
 *
 * Epoch days keep all menstrual-cycle arithmetic in pure common code; the platform
 * layer is responsible for converting calendar dates to epoch days.
 *
 * @property epochDay The day the rating was made, as days since 1970-01-01.
 * @property item The DRSP item number, 1–24.
 * @property score The reported severity, 1–6.
 */
data class DrspDailyScore(val epochDay: Int, val item: Int, val score: Int)

/**
 * Turns dated DRSP ratings into the cycle-relative [DrspObservation]s that
 * [CpassScorer] consumes, using the user's recorded menses onset dates.
 *
 * Following the C-PASS day convention (menses as the separating event), each day
 * is numbered relative to a menses onset: forward (1, 2, …) from the most recent
 * onset for post-menstrual days, and backward (−1, −2, …) from the next onset for
 * pre-menstrual days. A cycle is centered on a single onset, so that onset's
 * pre-menstrual week (days −7…−1) and post-menstrual week (days 4…10) share one
 * cycle number — exactly what the scorer compares.
 */
object CpassObservationMapper {
    /** The app tracks a single person; the scorer's subject field is constant. */
    const val SUBJECT: Int = 0

    /** A day within this many days before the next onset is treated as pre-menstrual. */
    private const val PRE_MENSTRUAL_LOOKBACK_DAYS = 14

    /**
     * A day this many days before the next onset (or fewer) is treated as
     * pre-menstrual and assigned to that upcoming cycle, matching the reference.
     */
    private val PRE_MENSTRUAL_WINDOW = -PRE_MENSTRUAL_LOOKBACK_DAYS..-1

    /**
     * Maps [scores] to cycle-relative observations using [mensesStartEpochDays].
     *
     * Returns an empty list when no menses onsets are known, since days cannot be
     * placed in a cycle without them. Ratings that cannot be anchored to any onset
     * are dropped.
     *
     * @param scores The dated DRSP ratings.
     * @param mensesStartEpochDays Menses onset dates as epoch days (any order).
     */
    fun toObservations(scores: List<DrspDailyScore>, mensesStartEpochDays: List<Int>): List<DrspObservation> {
        val starts = mensesStartEpochDays.distinct().sorted()
        if (starts.isEmpty()) return emptyList()
        return scores.mapNotNull { score ->
            val placement = place(score.epochDay, starts) ?: return@mapNotNull null
            DrspObservation(
                subject = SUBJECT,
                cycle = placement.cycle,
                day = placement.day,
                item = score.item,
                score = score.score,
            )
        }
    }

    private data class Placement(val cycle: Int, val day: Int)

    private fun place(epochDay: Int, starts: List<Int>): Placement? {
        val previousIndex = starts.indexOfLast { it <= epochDay }
        val nextIndex = starts.indexOfFirst { it > epochDay }
        val forwardDay = if (previousIndex >= 0) epochDay - starts[previousIndex] + 1 else null
        val backwardDay = if (nextIndex >= 0) epochDay - starts[nextIndex] else null
        return when {
            backwardDay != null && backwardDay in PRE_MENSTRUAL_WINDOW ->
                Placement(cycle = nextIndex + 1, day = backwardDay)
            forwardDay != null ->
                Placement(cycle = previousIndex + 1, day = forwardDay)
            backwardDay != null ->
                Placement(cycle = nextIndex + 1, day = backwardDay)
            else -> null
        }
    }
}
