// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

/**
 * Applies the Carolina Premenstrual Assessment Scoring System (C-PASS) to a set
 * of reported DRSP scores.
 *
 * This is a clean-room reimplementation of the published C-PASS procedure
 * (Eisenlohr-Moul et al., 2017, *American Journal of Psychiatry*), cross-checked
 * for identical output against the reference R package `lasy/cpass` (CC BY 4.0)
 * via the conformance suite. It is written from the specification, not ported
 * from the R source.
 *
 * The scorer is a pure, deterministic function over the data: it computes the
 * C-PASS item-, domain-, cycle-, and subject-level results and **never** renders
 * a diagnosis to the user. Mapping these results into factual, non-diagnostic,
 * "share this with your clinician" language is the responsibility of the
 * presentation layer, which stays gated until clinical review is complete.
 *
 * Missing-value handling mirrors the reference exactly, including how unknown
 * (null) booleans propagate, because the conformance suite requires byte-for-byte
 * agreement on the diagnoses.
 */
object CpassScorer {
    /** Minimum observed days required in each phase for an item/cycle to count. */
    private const val MIN_DAYS_PER_PHASE = 4

    /** A DRSP score at or above this is a "high" pre-menstrual score. */
    private const val HIGH_SCORE = 4

    /** Minimum pre-menstrual high-score days for an item to meet criteria. */
    private const val MIN_HIGH_SCORE_DAYS = 2

    /** Minimum pre-to-post percent drop for an item to meet criteria. */
    private const val MIN_PERCENT_CHANGE = 30.0

    /** DSM-5 criterion B: this many domains must meet criteria. */
    private const val MIN_DOMAINS_FOR_B = 5

    /** A subject-level diagnosis is only computed when more than one cycle scored. */
    private const val MIN_CYCLES_FOR_DIAGNOSIS = 1

    /** Minimum proportion of scored cycles meeting criteria for a subject. */
    private const val MIN_PROPORTION = 0.5

    /** Minimum count of qualifying cycles for a subject-level diagnosis. */
    private const val MIN_QUALIFYING_CYCLES = 2

    /** Multiplier turning a fraction into a percentage. */
    private const val PERCENT = 100.0

    /**
     * Scores [observations] and returns the full C-PASS result at every level.
     *
     * Observations may include any cycle days and unreported (null) scores; only
     * the pre- and post-menstrual windows are used, and the rest are ignored. The
     * set of cycles analysed is the distinct (subject, cycle) pairs present.
     *
     * @param observations The reported DRSP scores.
     * @return The item-, domain-, cycle-, and subject-level C-PASS results.
     */
    fun score(observations: List<DrspObservation>): CpassResult {
        // The cycles to analyse: every distinct (subject, cycle) that appears.
        val cycleKeys =
            observations
                .map { it.subject to it.cycle }
                .distinct()
                .sortedWith(compareBy({ it.first }, { it.second }))

        // Per subject, the score range is the highest score observed in the pre-
        // or post-menstrual phases minus one (the lowest possible score).
        val phaseObs =
            observations.filter { obs ->
                obs.score != null && CyclePhase.ofDay(obs.day) in SCORED_PHASES
            }
        val rangeBySubject: Map<Int, Int> =
            phaseObs
                .groupBy { it.subject }
                .mapValues { (_, obs) -> (obs.maxOf { it.score!! }) - DrspItem.MIN_SCORE }

        val items =
            cycleKeys.flatMap { (subject, cycle) ->
                DrspItem.entries.map { item ->
                    scoreItem(subject, cycle, item.number, phaseObs, rangeBySubject[subject])
                }
            }

        val itemsByCycle = items.groupBy { it.subject to it.cycle }
        val domains =
            cycleKeys.flatMap { (subject, cycle) ->
                scoreDomains(subject, cycle, itemsByCycle[subject to cycle].orEmpty())
            }

        val domainsByCycle = domains.groupBy { it.subject to it.cycle }
        val cycles =
            cycleKeys.map { (subject, cycle) ->
                scoreCycle(
                    subject,
                    cycle,
                    phaseObs.filter { it.subject == subject && it.cycle == cycle },
                    domainsByCycle[subject to cycle].orEmpty(),
                )
            }

        val subjects =
            cycles
                .groupBy { it.subject }
                .map { (subject, subjectCycles) -> scoreSubject(subject, subjectCycles) }
                .sortedBy { it.subject }

        return CpassResult(items = items, domains = domains, cycles = cycles, subjects = subjects)
    }

    /** The two phases that C-PASS scores. */
    private val SCORED_PHASES = setOf(CyclePhase.PRE_MENSES, CyclePhase.POST_MENSES)

    private fun scoreItem(
        subject: Int,
        cycle: Int,
        itemNumber: Int,
        phaseObs: List<DrspObservation>,
        range: Int?,
    ): ItemResult {
        val itemObs =
            phaseObs.filter {
                it.subject == subject && it.cycle == cycle && it.item == itemNumber
            }
        val pre = itemObs.filter { CyclePhase.ofDay(it.day) == CyclePhase.PRE_MENSES }.mapNotNull { it.score }
        val post = itemObs.filter { CyclePhase.ofDay(it.day) == CyclePhase.POST_MENSES }.mapNotNull { it.score }

        // Enough observations: at least MIN_DAYS_PER_PHASE in BOTH phases.
        val hasEnoughObservations = pre.size >= MIN_DAYS_PER_PHASE && post.size >= MIN_DAYS_PER_PHASE

        val maxSevPre = pre.maxOrNull()
        val nDaysHighScore = pre.count { it >= HIGH_SCORE }
        // No post-menstrual observation is treated as no clearance (max = high).
        val maxSevPost = post.maxOrNull() ?: HIGH_SCORE
        val meanPre = if (pre.isEmpty()) null else pre.average()
        val meanPost = if (post.isEmpty()) null else post.average()
        val percentChange = percentChange(meanPre, meanPost, range)
        val criteria = itemCriteria(hasEnoughObservations, maxSevPre, nDaysHighScore, maxSevPost, percentChange)

        return ItemResult(
            subject = subject,
            cycle = cycle,
            item = itemNumber,
            hasEnoughObservations = hasEnoughObservations,
            maxSevPre = maxSevPre,
            nDaysHighScore = nDaysHighScore,
            maxSevPost = maxSevPost,
            meanPre = meanPre,
            meanPost = meanPost,
            percentChange = percentChange,
            meetsPmddCriteria = criteria.pmdd,
            meetsPmeCriteria = criteria.pme,
        )
    }

    /** The pre-to-post drop as a percentage of the subject's range, or null. */
    private fun percentChange(meanPre: Double?, meanPost: Double?, range: Int?): Double? {
        val usableRange = range?.takeIf { it != 0 }
        if (meanPre == null || meanPost == null || usableRange == null) return null
        return (meanPre - meanPost) / usableRange * PERCENT
    }

    /** A single item's PMDD and PME criteria outcomes (null = undetermined). */
    private data class ItemCriteria(val pmdd: Boolean?, val pme: Boolean?)

    private fun itemCriteria(
        hasEnoughObservations: Boolean,
        maxSevPre: Int?,
        nDaysHighScore: Int,
        maxSevPost: Int,
        percentChange: Double?,
    ): ItemCriteria {
        if (!hasEnoughObservations) return ItemCriteria(pmdd = null, pme = null)
        val highPre = maxSevPre != null && maxSevPre >= HIGH_SCORE
        val enoughHighDays = nDaysHighScore >= MIN_HIGH_SCORE_DAYS
        val enoughChange = percentChange != null && percentChange >= MIN_PERCENT_CHANGE
        val pme = highPre && enoughHighDays && enoughChange
        val pmdd = pme && (maxSevPost < HIGH_SCORE)
        return ItemCriteria(pmdd = pmdd, pme = pme)
    }

    private fun scoreDomains(subject: Int, cycle: Int, cycleItems: List<ItemResult>): List<DomainResult> {
        // Only items that count toward domain diagnosis (excludes 20, 22–24).
        val contributing = cycleItems.filter { DrspItem.fromNumber(it.item).countsTowardDomainDiagnosis }
        return contributing
            .groupBy { DrspItem.fromNumber(it.item).domain }
            .map { (domain, domainItems) ->
                DomainResult(
                    subject = subject,
                    cycle = cycle,
                    domain = domain,
                    pmddCriteria = anyTrueOrNull(domainItems.map { it.meetsPmddCriteria }),
                    pmeCriteria = anyTrueOrNull(domainItems.map { it.meetsPmeCriteria }),
                )
            }
            .sortedBy { it.domain.ordinal }
    }

    private fun scoreCycle(
        subject: Int,
        cycle: Int,
        cyclePhaseObs: List<DrspObservation>,
        cycleDomains: List<DomainResult>,
    ): CycleResult {
        // Included: at least MIN_DAYS_PER_PHASE days with any observation in BOTH phases.
        val preDays =
            cyclePhaseObs
                .filter { CyclePhase.ofDay(it.day) == CyclePhase.PRE_MENSES }
                .map { it.day }.distinct().size
        val postDays =
            cyclePhaseObs
                .filter { CyclePhase.ofDay(it.day) == CyclePhase.POST_MENSES }
                .map { it.day }.distinct().size
        val included = preDays >= MIN_DAYS_PER_PHASE && postDays >= MIN_DAYS_PER_PHASE

        val coreEmotionalCriteria =
            anyTrueOrNull(
                cycleDomains
                    .filter { it.domain.category == SymptomCategory.CORE_EMOTIONAL }
                    .map { it.pmddCriteria },
            )
        // DSM-5 A: included AND a core emotional domain meets criteria (Kleene AND).
        val dsm5A = andIncluded(included, coreEmotionalCriteria)

        val nDomainsMeetingPmdd = countTrue(cycleDomains.map { it.pmddCriteria })
        val nDomainsMeetingPme = countTrue(cycleDomains.map { it.pmeCriteria })
        val dsm5B = included && (nDomainsMeetingPmdd >= MIN_DOMAINS_FOR_B)
        val pme = included && (nDomainsMeetingPme >= MIN_DOMAINS_FOR_B)

        val classification: CycleClassification? =
            when {
                dsm5A == null -> null
                !pme && !dsm5A -> CycleClassification.NO_DIAGNOSIS
                pme && !dsm5A -> CycleClassification.PME
                dsm5A && dsm5B -> CycleClassification.PMDD
                else -> CycleClassification.MRMD // dsm5A && !dsm5B
            }

        return CycleResult(
            subject = subject,
            cycle = cycle,
            included = included,
            nDomainsMeetingPmdd = nDomainsMeetingPmdd,
            nDomainsMeetingPme = nDomainsMeetingPme,
            pme = pme,
            dsm5A = dsm5A,
            dsm5B = dsm5B,
            classification = classification,
        )
    }

    private fun scoreSubject(subject: Int, subjectCycles: List<CycleResult>): SubjectResult {
        val nCyclesTotal = subjectCycles.size
        val nCyclesIncluded = subjectCycles.count { it.included }

        val avgDomainsMeetingPmdd =
            if (nCyclesIncluded == 0) {
                Double.NaN
            } else {
                subjectCycles.sumOf { if (it.included) it.nDomainsMeetingPmdd else 0 }
                    .toDouble() / nCyclesIncluded
            }

        // The subject-level summary needs more than one scored cycle.
        if (nCyclesIncluded <= MIN_CYCLES_FOR_DIAGNOSIS) {
            return SubjectResult(
                subject = subject,
                nCyclesTotal = nCyclesTotal,
                nCyclesIncluded = nCyclesIncluded,
                nPmddCycles = null,
                nMrmdCycles = null,
                nPmeCycles = null,
                meetsPmdd = null,
                meetsMrmd = null,
                meetsPme = null,
                classification = null,
                avgDomainsMeetingPmdd = avgDomainsMeetingPmdd,
            )
        }

        // sum(diagnosis == "PMDD") / sum(DSM5_A): unknowns propagate (no na.rm).
        val nPmdd = sumOrNull(subjectCycles.map { it.classification?.let { c -> c == CycleClassification.PMDD } })
        val nMrmd = sumOrNull(subjectCycles.map { it.dsm5A })
        val nPme = countTrue(subjectCycles.map { it.pme })

        val meetsPmdd = meetsThreshold(nPmdd, nCyclesIncluded)
        val meetsMrmd = meetsThreshold(nMrmd, nCyclesIncluded)
        val meetsPme = meetsThreshold(nPme, nCyclesIncluded) == true
        val classification = subjectClassification(meetsPmdd, meetsMrmd, meetsPme)

        return SubjectResult(
            subject = subject,
            nCyclesTotal = nCyclesTotal,
            nCyclesIncluded = nCyclesIncluded,
            nPmddCycles = nPmdd,
            nMrmdCycles = nMrmd,
            nPmeCycles = nPme,
            meetsPmdd = meetsPmdd,
            meetsMrmd = meetsMrmd,
            meetsPme = meetsPme,
            classification = classification,
            avgDomainsMeetingPmdd = avgDomainsMeetingPmdd,
        )
    }

    /**
     * Whether [count] qualifying cycles out of [nCycles] scored meets the
     * subject-level bar: at least [MIN_QUALIFYING_CYCLES] and a majority. Null
     * propagates an undetermined count.
     */
    private fun meetsThreshold(count: Int?, nCycles: Int): Boolean? =
        count?.let { it >= MIN_QUALIFYING_CYCLES && it.toDouble() / nCycles >= MIN_PROPORTION }

    /** Resolves the subject-level label, preferring PMDD over MRMD over PME. */
    private fun subjectClassification(
        meetsPmdd: Boolean?,
        meetsMrmd: Boolean?,
        meetsPme: Boolean,
    ): SubjectClassification =
        when {
            meetsPmdd == true -> SubjectClassification.PMDD
            meetsMrmd == true -> SubjectClassification.MRMD
            meetsPme -> SubjectClassification.PME
            else -> SubjectClassification.NO_DIAGNOSIS
        }
}

// --- Reference-faithful missing-value helpers --------------------------------
// These mirror R's NA semantics for the specific reductions C-PASS uses; the
// conformance suite depends on this propagation matching exactly.

/**
 * Mirrors `ifelse(all(is.na(x)), NA, any(x, na.rm = TRUE))`: null when every
 * value is unknown, otherwise whether any known value is true.
 */
private fun anyTrueOrNull(values: List<Boolean?>): Boolean? =
    if (values.all { it == null }) null else values.any { it == true }

/**
 * R's logical `&` where the left operand is a known boolean: false short-
 * circuits to false; otherwise the (possibly unknown) right operand governs.
 */
private fun andIncluded(included: Boolean, other: Boolean?): Boolean? = if (!included) false else other

/** Mirrors `sum(x, na.rm = TRUE)` over booleans: count of known-true values. */
private fun countTrue(values: List<Boolean?>): Int = values.count { it == true }

/**
 * Mirrors `sum(x)` over booleans with no `na.rm`: null if any value is
 * unknown, otherwise the count of true values.
 */
private fun sumOrNull(values: List<Boolean?>): Int? =
    if (values.any { it == null }) null else values.count { it == true }
