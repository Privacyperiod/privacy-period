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
 * Algorithm: average the lengths of up to the last six inter-period intervals
 * (requiring at least [MIN_LOGGED_PERIODS] logged period starts), then add
 * that average to the most recent period start date. Intervals outside 10–90
 * days are discarded as likely data entry errors.
 *
 * This engine owns no state and performs no I/O.
 */
object CyclePredictionEngine {
    // 3 logged period starts → 2 measurable intervals → first prediction.
    const val MIN_LOGGED_PERIODS = 3

    /** Produces a prediction from a full [ClinicalHistory]. */
    fun predict(history: ClinicalHistory): CyclePredictionResult = predict(history.cycles)

    /** Produces a prediction from a raw list of [Cycle] objects, sorted by start date. */
    fun predict(cycles: List<Cycle>): CyclePredictionResult {
        val sorted = cycles.sortedBy { it.startDate }
        val n = sorted.size

        if (n < MIN_LOGGED_PERIODS) {
            return CyclePredictionResult(
                predictedDate = null,
                averageCycleDays = 0.0,
                cyclesUsed = 0,
                isReady = false,
                cyclesNeeded = MIN_LOGGED_PERIODS - n,
            )
        }

        // Use up to the 7 most recent cycle starts → up to 6 intervals.
        val window = sorted.takeLast(7)
        val lengths = mutableListOf<Int>()
        for (i in 1 until window.size) {
            val prev = IsoDate.toEpochDay(window[i - 1].startDate) ?: continue
            val curr = IsoDate.toEpochDay(window[i].startDate) ?: continue
            val diff = curr - prev
            // Discard outliers: <10 days is a duplicate entry, >90 days is a missed cycle.
            if (diff in 10..90) lengths.add(diff)
        }

        if (lengths.isEmpty()) {
            return CyclePredictionResult(
                predictedDate = null,
                averageCycleDays = 0.0,
                cyclesUsed = 0,
                isReady = false,
                cyclesNeeded = MIN_LOGGED_PERIODS,
            )
        }

        val averageDays = lengths.average()
        val lastStart = IsoDate.toEpochDay(sorted.last().startDate)
            ?: return CyclePredictionResult(
                predictedDate = null,
                averageCycleDays = averageDays,
                cyclesUsed = lengths.size,
                isReady = false,
                cyclesNeeded = 0,
            )

        val predictedDate = IsoDate.fromEpochDay(lastStart + averageDays.toInt())
        return CyclePredictionResult(
            predictedDate = predictedDate,
            averageCycleDays = averageDays,
            cyclesUsed = lengths.size,
            isReady = true,
            cyclesNeeded = 0,
        )
    }
}
