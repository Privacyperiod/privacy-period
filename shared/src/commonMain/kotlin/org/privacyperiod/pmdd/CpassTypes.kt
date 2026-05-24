// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

/**
 * The phase of a menstrual cycle that a given cycle day belongs to, using the
 * C-PASS day convention: days are counted backward (-1, -2, …) before menses and
 * forward (1, 2, …) from the first day of menses, with no day 0.
 *
 * C-PASS compares a fixed pre-menstrual window with a fixed post-menstrual one;
 * only those two phases are scored.
 */
enum class CyclePhase {
    /** Days −7 to −1: the pre-menstrual week compared in C-PASS. */
    PRE_MENSES,

    /** Days 1 to 3: the menstrual days, recorded but not scored. */
    MENSES,

    /** Days 4 to 10: the post-menstrual week compared in C-PASS. */
    POST_MENSES,

    /** Any other day; recorded but not scored. */
    PERI_OVULATION,

    ;

    companion object {
        /** Inclusive pre-menstrual window, in C-PASS day numbers. */
        val PRE_MENSES_DAYS: IntRange = -7..-1

        /** Inclusive menstrual window, in C-PASS day numbers. */
        val MENSES_DAYS: IntRange = 1..3

        /** Inclusive post-menstrual window, in C-PASS day numbers. */
        val POST_MENSES_DAYS: IntRange = 4..10

        /**
         * Maps a C-PASS [day] number to its [CyclePhase].
         *
         * @param day The cycle day, negative before menses and positive from the
         *   first menstrual day; there is no day 0.
         */
        fun ofDay(day: Int): CyclePhase =
            when (day) {
                in PRE_MENSES_DAYS -> PRE_MENSES
                in MENSES_DAYS -> MENSES
                in POST_MENSES_DAYS -> POST_MENSES
                else -> PERI_OVULATION
            }
    }
}

/**
 * One reported DRSP score: a [subject]'s rating of one [item] on one [day] of one
 * [cycle].
 *
 * For the app there is a single subject (this device); the subject field exists
 * so the same scorer can be validated against multi-subject reference datasets.
 *
 * @property subject Identifier for the person reporting.
 * @property cycle The menses-centered cycle number (a positive integer).
 * @property day The C-PASS day number (negative before menses, positive from the
 *   first menstrual day; never 0).
 * @property item The DRSP item number, 1–24.
 * @property score The reported severity 1–6, or null if not reported that day.
 */
data class DrspObservation(
    val subject: Int,
    val cycle: Int,
    val day: Int,
    val item: Int,
    val score: Int?,
)

/**
 * Whether a single cycle meets premenstrual-disorder criteria, per C-PASS.
 *
 * This is an analytic label for one cycle, never a clinical diagnosis for the
 * person. The C-PASS labels map as follows: no diagnosis; PME (premenstrual
 * exacerbation); MRMD (menstrually related mood disorder, DSM-5 criterion A only);
 * and the full premenstrual-dysphoric pattern (criteria A and B).
 */
enum class CycleClassification {
    NO_DIAGNOSIS,
    PME,
    MRMD,
    PMDD,
}

/**
 * The subject-level classification accumulated across cycles, per C-PASS.
 *
 * As with [CycleClassification], this is an analytic summary of tracked data, not
 * a clinical diagnosis. It is only defined when more than one cycle was tracked.
 */
enum class SubjectClassification {
    NO_DIAGNOSIS,
    MRMD,
    PMDD,
    PME,
}

/**
 * Per-item C-PASS measures for one subject, cycle, and DRSP item.
 *
 * @property maxSevPre Highest pre-menstrual score, or null if none observed.
 * @property nDaysHighScore Pre-menstrual days scored 4 or higher.
 * @property maxSevPost Highest post-menstrual score; defaults to 4 (i.e. no
 *   clearance) when no post-menstrual scores were observed.
 * @property percentChange Pre-to-post drop as a percentage of the subject's score
 *   range, or null when it cannot be computed.
 * @property meetsPmddCriteria Whether the item meets the per-item premenstrual
 *   criteria including post-menstrual clearance; null when there were too few
 *   observations to decide.
 * @property meetsPmeCriteria As [meetsPmddCriteria] but without the clearance
 *   requirement (premenstrual exacerbation).
 */
data class ItemResult(
    val subject: Int,
    val cycle: Int,
    val item: Int,
    val hasEnoughObservations: Boolean,
    val maxSevPre: Int?,
    val nDaysHighScore: Int,
    val maxSevPost: Int,
    val meanPre: Double?,
    val meanPost: Double?,
    val percentChange: Double?,
    val meetsPmddCriteria: Boolean?,
    val meetsPmeCriteria: Boolean?,
)

/**
 * Per-domain C-PASS result for one subject and cycle.
 *
 * @property pmddCriteria Whether any contributing item meets the per-item PMDD
 *   criteria; null when none of the domain's items had enough observations.
 * @property pmeCriteria As [pmddCriteria] but for the PME (no-clearance) criteria.
 */
data class DomainResult(
    val subject: Int,
    val cycle: Int,
    val domain: Dsm5Domain,
    val pmddCriteria: Boolean?,
    val pmeCriteria: Boolean?,
)

/**
 * Per-cycle C-PASS result for one subject.
 *
 * @property included Whether the cycle had enough observed days in both phases to
 *   be scored.
 * @property nDomainsMeetingPmdd Number of DSM-5 domains meeting the PMDD criteria.
 * @property nDomainsMeetingPme Number of DSM-5 domains meeting the PME criteria.
 * @property dsm5A DSM-5 criterion A (a core emotional domain meets criteria);
 *   null when it could not be determined.
 * @property dsm5B DSM-5 criterion B (five or more domains meet criteria).
 * @property classification The cycle's C-PASS label; null when it could not be
 *   determined (criterion A undetermined).
 */
data class CycleResult(
    val subject: Int,
    val cycle: Int,
    val included: Boolean,
    val nDomainsMeetingPmdd: Int,
    val nDomainsMeetingPme: Int,
    val pme: Boolean,
    val dsm5A: Boolean?,
    val dsm5B: Boolean,
    val classification: CycleClassification?,
)

/**
 * Subject-level C-PASS result, summarizing across that subject's cycles.
 *
 * @property nCyclesTotal Total cycles recorded.
 * @property nCyclesIncluded Cycles with enough data to be scored.
 * @property nPmddCycles Cycles classified PMDD; null when only one cycle was
 *   scored (the subject-level summary needs more than one).
 * @property nMrmdCycles Cycles meeting DSM-5 criterion A; null as above.
 * @property nPmeCycles Cycles meeting PME; null as above.
 * @property classification The subject's overall C-PASS label; null when only one
 *   cycle was scored.
 */
data class SubjectResult(
    val subject: Int,
    val nCyclesTotal: Int,
    val nCyclesIncluded: Int,
    val nPmddCycles: Int?,
    val nMrmdCycles: Int?,
    val nPmeCycles: Int?,
    val meetsPmdd: Boolean?,
    val meetsMrmd: Boolean?,
    val meetsPme: Boolean?,
    val classification: SubjectClassification?,
    val avgDomainsMeetingPmdd: Double,
)

/**
 * The full set of C-PASS results at every level, returned by [CpassScorer.score].
 */
data class CpassResult(
    val items: List<ItemResult>,
    val domains: List<DomainResult>,
    val cycles: List<CycleResult>,
    val subjects: List<SubjectResult>,
)
