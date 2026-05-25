// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

/**
 * The Greene Climacteric Scale scorer — a clean-room implementation of the
 * published Greene (1998) scoring, used by the Perimenopause module.
 *
 * Each of the 21 items is rated 0 ("not at all") to 3 ("extremely"); the scorer
 * sums items into the six domains ([GreeneSubscale] plus the combined
 * Psychological total). The Greene scale is a **symptom-severity profile**, not a
 * diagnostic test — there is no cutoff, and this scorer never states a diagnosis.
 *
 * The Greene Climacteric Scale is freely available and requires no permission for
 * use; the item *wording* is referenced by number in the UI (the official text can
 * be shown verbatim, as no licence restricts it). The module stays gated until
 * clinical sign-off.
 */
object GreeneScale {
    /** Number of items in the scale. */
    const val ITEM_COUNT: Int = 21

    /** Minimum per-item score ("not at all"). */
    const val MIN_SCORE: Int = 0

    /** Maximum per-item score ("extremely"). */
    const val MAX_SCORE: Int = 3

    /**
     * Scores answered items into the Greene domain profile. Missing items count as
     * 0 toward their domain; [GreeneResult.isComplete] reports whether all 21 were
     * answered. Item scores outside 0–3 are clamped.
     */
    fun score(itemScores: Map<Int, Int>): GreeneResult {
        val subscales =
            GreeneSubscale.entries.associateWith { subscale ->
                subscale.items.sumOf { clamp(itemScores[it] ?: MIN_SCORE) }
            }
        val psychological =
            subscales.getValue(GreeneSubscale.ANXIETY) + subscales.getValue(GreeneSubscale.DEPRESSION)
        return GreeneResult(
            subscales = subscales,
            psychological = psychological,
            total = subscales.values.sum(),
            isComplete = (1..ITEM_COUNT).all { it in itemScores },
        )
    }

    private fun clamp(score: Int): Int = score.coerceIn(MIN_SCORE, MAX_SCORE)
}
