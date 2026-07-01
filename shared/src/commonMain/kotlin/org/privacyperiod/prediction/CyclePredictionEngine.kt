// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.prediction

import org.privacyperiod.clinical.ClinicalHistory
import org.privacyperiod.clinical.Cycle
import org.privacyperiod.clinical.IsoDate

/**
 * Result of a next-period prediction.
 *
 * @property predictedDate ISO-8601 predicted start date, or null when [isReady] is false.
 * @property averageCycleDays Average cycle length used in the prediction.
 * @property cyclesUsed Number of inter-period intervals averaged.
 * @property isReady True once enough history exists to produce a prediction.
 * @property cyclesNeeded How many more logged periods are needed before [isReady].
 */
data class CyclePredictionResult(
    val predictedDate: String?,
    val averageCycleDays: Double,
    val cyclesUsed: Int,
    val isReady: Boolean,
    val cyclesNeeded: Int,
)

/**
 * Predicts the next period start date from the user's logged cycle history.
 *
 * Algorithm: average the lengths of up to the last [INTERVAL_WINDOW] inter-period
 * intervals (requiring at least [MIN_LOGGED_PERIODS] logged period starts), then
 * add that average to the most recent period start date. Intervals outside
 * [MIN_CYCLE_DAYS]–[MAX_CYCLE_DAYS] days are discarded as likely data entry
 * errors or missed-cycle gaps.
 *
 * This engine owns no state and performs no I/O.
 */
object CyclePredictionEngine {
    /** Minimum number of logged period starts required before a prediction is made. */
    const val MIN_LOGGED_PERIODS = 3

    /** Maximum number of recent cycle-start dates considered when averaging. */
    private const val WINDOW_SIZE = 7

    /** Number of inter-period intervals derived from [WINDOW_SIZE] cycle starts. */
    private const val INTERVAL_WINDOW = WINDOW_SIZE - 1

    /** Minimum plausible inter-period gap; shorter gaps indicate a duplicate entry. */
    private const val MIN_CYCLE_DAYS = 10

    /** Maximum plausible inter-period gap; longer gaps indicate a missed cycle. */
    private const val MAX_CYCLE_DAYS = 90

    /** Produces a prediction from a full [ClinicalHistory]. */
    fun predict(history: ClinicalHistory): CyclePredictionResult = predict(history.cycles)

    /**
     * Produces a prediction from a raw list of [Cycle] objects.
     *
     * @param cycles All logged cycles; need not be sorted.
     * @return A [CyclePredictionResult] indicating readiness and the predicted date.
     */
    fun predict(cycles: List<Cycle>): CyclePredictionResult {
        val sorted = cycles.sortedBy { it.startDate }
        val n = sorted.size

        val intervals = buildIntervals(sorted)

        if (n < MIN_LOGGED_PERIODS || intervals.isEmpty()) {
            return CyclePredictionResult(
                predictedDate = null,
                averageCycleDays = 0.0,
                cyclesUsed = 0,
                isReady = false,
                cyclesNeeded = if (n < MIN_LOGGED_PERIODS) MIN_LOGGED_PERIODS - n else MIN_LOGGED_PERIODS,
            )
        }

        val averageDays = intervals.average()
        val lastStart = IsoDate.toEpochDay(sorted.last().startDate)
        val predictedDate = lastStart?.let { IsoDate.fromEpochDay(it + averageDays.toInt()) }
        return CyclePredictionResult(
            predictedDate = predictedDate,
            averageCycleDays = averageDays,
            cyclesUsed = intervals.size,
            isReady = lastStart != null,
            cyclesNeeded = 0,
        )
    }

    /**
     * Computes plausible inter-period intervals from the most recent [WINDOW_SIZE]
     * cycles, discarding gaps outside [[MIN_CYCLE_DAYS]..[MAX_CYCLE_DAYS]].
     */
    private fun buildIntervals(sorted: List<Cycle>): List<Int> =
        sorted.takeLast(WINDOW_SIZE)
            .zipWithNext()
            .mapNotNull { (prev, curr) ->
                val prevDay = IsoDate.toEpochDay(prev.startDate) ?: return@mapNotNull null
                val currDay = IsoDate.toEpochDay(curr.startDate) ?: return@mapNotNull null
                val diff = currDay - prevDay
                diff.takeIf { it in MIN_CYCLE_DAYS..MAX_CYCLE_DAYS }
            }
            .takeLast(INTERVAL_WINDOW)
}
