// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import org.privacyperiod.clinical.ClinicalHistory
import org.privacyperiod.clinical.ClinicalModule
import org.privacyperiod.clinical.IsoDate
import org.privacyperiod.clinical.ReadinessResult
import org.privacyperiod.clinical.ScoringResult

/**
 * The PMDD screening module, implemented against the universal data layer.
 *
 * It requires the 24 DRSP items (from [DrspCatalog]), reads same-day DRSP ratings
 * from the [ClinicalHistory], maps them to cycle-relative observations using the
 * logged menses onsets ([CpassObservationMapper]), and scores them with the
 * conformance-verified [CpassScorer]. It owns no storage and never renders a
 * diagnosis; the presentation layer frames the result factually.
 */
object PmddModule : ClinicalModule {
    /** PMDD needs at least two scored cycles for a subject-level result. */
    private const val MIN_CYCLES = 2

    override val id: String = "pmdd"
    override val nameKey: String = "module.pmdd.name"
    override val requiredSymptoms: Set<String> = DrspCatalog.definitions.map { it.id }.toSet()
    override val sameDayEnforced: Boolean = true
    override val minimumCyclesForScoring: Int = MIN_CYCLES

    override fun checkReadiness(history: ClinicalHistory): ReadinessResult {
        val scoredCycles = score(history).result.cycles.count { it.included }
        return ReadinessResult(isReady = scoredCycles >= minimumCyclesForScoring, scoredCycles = scoredCycles)
    }

    override fun runScoring(history: ClinicalHistory): ScoringResult = score(history)

    private fun score(history: ClinicalHistory): PmddScoringResult {
        // C-PASS requires prospective ratings, so only same-day entries count.
        val entries =
            if (sameDayEnforced) {
                history.sameDaySymptomEntries(requiredSymptoms)
            } else {
                history.symptomEntries(requiredSymptoms)
            }
        val scores =
            entries.mapNotNull { entry ->
                val item = DrspCatalog.itemNumber(entry.symptomId) ?: return@mapNotNull null
                val epochDay = IsoDate.toEpochDay(entry.date) ?: return@mapNotNull null
                DrspDailyScore(epochDay = epochDay, item = item, score = entry.severity.toInt())
            }
        val mensesStarts = history.cycles.mapNotNull { IsoDate.toEpochDay(it.startDate) }
        val observations = CpassObservationMapper.toObservations(scores, mensesStarts)
        return PmddScoringResult(CpassScorer.score(observations))
    }
}

/** The PMDD module's scoring output: the full C-PASS result. */
data class PmddScoringResult(val result: CpassResult) : ScoringResult
