// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pme

import org.privacyperiod.clinical.ClinicalHistory
import org.privacyperiod.clinical.ClinicalModule
import org.privacyperiod.clinical.IsoDate
import org.privacyperiod.clinical.ReadinessResult
import org.privacyperiod.clinical.ScoringResult
import org.privacyperiod.pmdd.CpassObservationMapper
import org.privacyperiod.pmdd.CpassScorer
import org.privacyperiod.pmdd.DrspCatalog
import org.privacyperiod.pmdd.DrspDailyScore
import org.privacyperiod.pmdd.DrspObservation
import org.privacyperiod.pmdd.PatternClassification
import org.privacyperiod.pmdd.PmddVsPmePatternClassifier

/**
 * The PME (premenstrual exacerbation) screening module, on the universal layer.
 *
 * PME is for users with an existing, previously diagnosed condition whose
 * symptoms worsen premenstrually. The module tracks the MAC-PMSS — the DRSP items
 * (reused from [DrspCatalog]) plus the MAC-PMSS mood-chart items
 * ([MacPmssCatalog]) — and runs the PMDD-vs-PME differentiation, which keys on the
 * follicular baseline. It never diagnoses the underlying condition or PME; it
 * reports a pattern to share with a clinician. Gated until clinical sign-off.
 */
object PmeModule : ClinicalModule {
    /** Two scored cycles are the minimum for a prospective pattern. */
    private const val MIN_CYCLES = 2

    override val id: String = "pme"
    override val nameKey: String = "module.pme.name"
    override val requiredSymptoms: Set<String> =
        DrspCatalog.definitions.map { it.id }.toSet() + MacPmssCatalog.definitions.map { it.id }.toSet()
    override val sameDayEnforced: Boolean = true
    override val minimumCyclesForScoring: Int = MIN_CYCLES

    override fun checkReadiness(history: ClinicalHistory): ReadinessResult {
        val scoredCycles = CpassScorer.score(observations(history)).cycles.count { it.included }
        return ReadinessResult(isReady = scoredCycles >= minimumCyclesForScoring, scoredCycles = scoredCycles)
    }

    override fun runScoring(history: ClinicalHistory): ScoringResult =
        PmeScoringResult(PmddVsPmePatternClassifier.classify(observations(history)))

    // The differentiation keys on the DRSP mood/cognitive items; MAC-PMSS
    // mood-chart entries are tracked for the clinical picture but are not part of
    // the follicular-vs-luteal computation, so only the DRSP entries are mapped.
    private fun observations(history: ClinicalHistory): List<DrspObservation> {
        val entries = history.sameDaySymptomEntries(requiredSymptoms)
        val scores =
            entries.mapNotNull { entry ->
                val item = DrspCatalog.itemNumber(entry.symptomId) ?: return@mapNotNull null
                val epochDay = IsoDate.toEpochDay(entry.date) ?: return@mapNotNull null
                DrspDailyScore(epochDay = epochDay, item = item, score = entry.severity.toInt())
            }
        val mensesStarts = history.cycles.mapNotNull { IsoDate.toEpochDay(it.startDate) }
        return CpassObservationMapper.toObservations(scores, mensesStarts)
    }
}

/** The PME module's output: the cyclicity pattern classification. */
data class PmeScoringResult(val classification: PatternClassification) : ScoringResult
