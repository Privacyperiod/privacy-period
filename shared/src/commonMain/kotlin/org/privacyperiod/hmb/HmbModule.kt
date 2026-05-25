// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.hmb

import org.privacyperiod.clinical.ClinicalHistory
import org.privacyperiod.clinical.ClinicalModule
import org.privacyperiod.clinical.FlowEvent
import org.privacyperiod.clinical.ReadinessResult
import org.privacyperiod.clinical.ScoringResult

/**
 * The Heavy Menstrual Bleeding (HMB) screening module, on the universal layer.
 *
 * Unlike the symptom-rating modules, HMB scores **flow events** with the
 * [PbacScorer]: each cycle that has logged flow is scored independently (PBAC is a
 * per-cycle measure, so a single cycle can be assessed). It never diagnoses; it
 * reports a per-cycle classification to share with a clinician. Gated until
 * clinical sign-off (see [HmbFeature]).
 */
object HmbModule : ClinicalModule {
    /** One cycle with logged flow is enough to produce a PBAC score. */
    private const val MIN_CYCLES = 1

    override val id: String = "hmb"
    override val nameKey: String = "module.hmb.name"

    // HMB scores flow_events, not symptom_definitions.
    override val requiredSymptoms: Set<String> = emptySet()
    override val sameDayEnforced: Boolean = false
    override val minimumCyclesForScoring: Int = MIN_CYCLES

    override fun checkReadiness(history: ClinicalHistory): ReadinessResult {
        val scored = scoredCycles(history).size
        return ReadinessResult(isReady = scored >= minimumCyclesForScoring, scoredCycles = scored)
    }

    override fun runScoring(history: ClinicalHistory): ScoringResult = HmbScoringResult(scoredCycles(history))

    // One PBAC score per cycle that has at least one flow event, oldest cycle first.
    private fun scoredCycles(history: ClinicalHistory): List<HmbCycleScore> {
        val eventsByCycle = history.flowEvents().groupBy { it.cycleId }
        return history.cycles.mapNotNull { cycle ->
            val events = eventsByCycle[cycle.id].orEmpty()
            if (events.isEmpty()) {
                null
            } else {
                HmbCycleScore(cycle.id, cycle.startDate, PbacScorer.scoreCycle(events.map { it.toInput() }))
            }
        }
    }

    private fun FlowEvent.toInput(): FlowEventInput =
        FlowEventInput(flowType = flowType, saturation = saturation, clotSize = clotSize, measuredMl = measuredMl)
}

/**
 * One cycle's HMB result.
 *
 * @property cycleId The scored cycle.
 * @property startDate The cycle's start date (ISO-8601), for display ordering.
 * @property score The cycle's PBAC score and classification.
 */
data class HmbCycleScore(val cycleId: String, val startDate: String, val score: PbacScore)

/** The HMB module's output: the per-cycle PBAC scores, oldest cycle first. */
data class HmbScoringResult(val cycles: List<HmbCycleScore>) : ScoringResult
