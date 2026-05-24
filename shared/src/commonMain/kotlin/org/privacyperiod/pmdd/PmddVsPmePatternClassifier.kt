// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

/**
 * Distinguishes a PMDD-like pattern from premenstrual exacerbation (PME) of an
 * existing condition.
 *
 * The clinical distinction is in the *follicular baseline*, not the luteal peak:
 * PMDD has a low/normal follicular baseline that rises premenstrually, while PME
 * has an already-elevated baseline that rises further. This classifier compares,
 * for the differentiating mood/cognitive symptoms, the follicular-phase mean
 * (post-menstrual window) against the luteal-phase mean (pre-menstrual window),
 * following the framework in the project's module-plans documentation
 * (Eisenlohr-Moul et al.; MAC-PMSS validation).
 *
 * The thresholds are the documented starting values and are **pending clinical
 * confirmation**; the module that surfaces this is gated until sign-off. Output
 * is never a diagnosis — it is a pattern, to share with a clinician.
 */
object PmddVsPmePatternClassifier {
    /**
     * The DRSP items that distinguish an ongoing mood disorder from PMDD:
     * depressed mood (1), anxiety (4), anger/irritability (7), decreased
     * interest (9), difficulty concentrating (10), lethargy (11), overwhelmed (16).
     * These are DRSP item numbers, not arbitrary constants.
     */
    @Suppress("MagicNumber")
    val DIFFERENTIATING_ITEMS: List<Int> = listOf(1, 4, 7, 9, 10, 11, 16)

    /** A follicular mean above this counts as an elevated baseline (1–6 scale). */
    private const val FOLLICULAR_BASELINE_THRESHOLD = 2.5

    /** A luteal mean above this counts as a premenstrual elevation (1–6 scale). */
    private const val LUTEAL_ELEVATION_THRESHOLD = 3.5

    /** A luteal/follicular ratio above this is a meaningful premenstrual rise. */
    private const val ELEVATION_RATIO_THRESHOLD = 1.3

    /** "Several" symptoms for the pattern rules. */
    private const val MANY_DOMAINS = 3

    /** "At most one" symptom for the pattern rules. */
    private const val FEW_DOMAINS = 1

    /** Divisor floor so the ratio is defined when the follicular mean is tiny. */
    private const val RATIO_FLOOR = 1.0

    /**
     * Classifies the cyclicity pattern across [observations] (the same
     * cycle-relative DRSP observations the C-PASS scorer consumes).
     */
    fun classify(observations: List<DrspObservation>): PatternClassification {
        val symptoms = DIFFERENTIATING_ITEMS.map { item -> symptomPattern(item, observations) }
        val follicularElevated = symptoms.count { it.follicularElevated }
        val lutealElevated = symptoms.count { it.lutealElevated }
        val ratios = symptoms.mapNotNull { it.elevationRatio }
        val averageRatio = if (ratios.isEmpty()) 0.0 else ratios.average()

        val pattern =
            when {
                follicularElevated <= FEW_DOMAINS && lutealElevated >= MANY_DOMAINS ->
                    CyclicityPattern.PMDD_CONSISTENT
                follicularElevated >= MANY_DOMAINS && lutealElevated >= MANY_DOMAINS &&
                    averageRatio > ELEVATION_RATIO_THRESHOLD ->
                    CyclicityPattern.PME_CONSISTENT
                follicularElevated >= MANY_DOMAINS && averageRatio <= ELEVATION_RATIO_THRESHOLD ->
                    CyclicityPattern.ONGOING_NO_CYCLICAL_CHANGE
                follicularElevated <= FEW_DOMAINS && lutealElevated <= FEW_DOMAINS ->
                    CyclicityPattern.NO_CYCLICAL_PATTERN
                else -> CyclicityPattern.INDETERMINATE
            }
        return PatternClassification(pattern = pattern, symptoms = symptoms)
    }

    private fun symptomPattern(item: Int, observations: List<DrspObservation>): SymptomPattern {
        // Follicular ≈ the post-menstrual window; luteal ≈ the pre-menstrual window.
        val follicular = phaseScores(item, observations, CyclePhase.POST_MENSES)
        val luteal = phaseScores(item, observations, CyclePhase.PRE_MENSES)
        val follicularMean = if (follicular.isEmpty()) null else follicular.average()
        val lutealMean = if (luteal.isEmpty()) null else luteal.average()
        val ratio =
            if (follicularMean != null && lutealMean != null) {
                lutealMean / maxOf(follicularMean, RATIO_FLOOR)
            } else {
                null
            }
        return SymptomPattern(
            item = item,
            follicularMean = follicularMean,
            lutealMean = lutealMean,
            follicularElevated = follicularMean != null && follicularMean > FOLLICULAR_BASELINE_THRESHOLD,
            lutealElevated = lutealMean != null && lutealMean > LUTEAL_ELEVATION_THRESHOLD,
            elevationRatio = ratio,
        )
    }

    private fun phaseScores(item: Int, observations: List<DrspObservation>, phase: CyclePhase): List<Int> =
        observations
            .filter { it.item == item && it.score != null && CyclePhase.ofDay(it.day) == phase }
            .mapNotNull { it.score }
}

/** The cyclicity pattern a user's tracked symptoms show. */
enum class CyclicityPattern {
    /** Low follicular baseline, high luteal — consistent with the PMDD pattern. */
    PMDD_CONSISTENT,

    /** Elevated baseline that rises further premenstrually — consistent with PME. */
    PME_CONSISTENT,

    /** Elevated baseline with no premenstrual rise — an ongoing condition. */
    ONGOING_NO_CYCLICAL_CHANGE,

    /** Neither phase elevated — no cyclical pattern. */
    NO_CYCLICAL_PATTERN,

    /** The data does not fit a single pattern. */
    INDETERMINATE,
}

/**
 * Per-symptom follicular vs. luteal comparison feeding the pattern classification.
 *
 * @property item The DRSP item number.
 * @property follicularMean Mean post-menstrual severity, or null if none observed.
 * @property lutealMean Mean pre-menstrual severity, or null if none observed.
 * @property elevationRatio Luteal mean over follicular mean (floored), or null.
 */
data class SymptomPattern(
    val item: Int,
    val follicularMean: Double?,
    val lutealMean: Double?,
    val follicularElevated: Boolean,
    val lutealElevated: Boolean,
    val elevationRatio: Double?,
)

/** The differentiation result: the overall pattern and its per-symptom detail. */
data class PatternClassification(
    val pattern: CyclicityPattern,
    val symptoms: List<SymptomPattern>,
)
