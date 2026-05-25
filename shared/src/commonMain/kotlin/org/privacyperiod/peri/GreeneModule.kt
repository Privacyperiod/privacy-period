// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

import org.privacyperiod.clinical.ClinicalHistory
import org.privacyperiod.clinical.ClinicalModule
import org.privacyperiod.clinical.ReadinessResult
import org.privacyperiod.clinical.ScoringResult

/**
 * The Perimenopause screening module, on the universal layer.
 *
 * Greene is a periodic questionnaire, not a daily or per-cycle measure, so it is
 * stored as [org.privacyperiod.clinical.InstrumentCompletion]s rather than daily
 * symptom entries. Each completion is scored with [GreeneScale] into a
 * symptom-severity profile; tracking completions over time shows the trend. It
 * never diagnoses; Greene has no diagnostic cutoff. Gated until clinical sign-off
 * (see [PeriFeature]).
 */
object GreeneModule : ClinicalModule {
    /** The `instrument_completions.instrument_type` value for the Greene scale. */
    const val INSTRUMENT_TYPE: String = "greene_climacteric"

    /** One completed questionnaire is enough to show a profile. */
    private const val MIN_COMPLETIONS = 1

    override val id: String = "perimenopause"
    override val nameKey: String = "module.peri.name"

    // Greene uses instrument_completions, not the daily symptom catalogue.
    override val requiredSymptoms: Set<String> = emptySet()
    override val sameDayEnforced: Boolean = false

    // "Cycles" is the generic readiness count; for Greene it is the completion count.
    override val minimumCyclesForScoring: Int = MIN_COMPLETIONS

    override fun checkReadiness(history: ClinicalHistory): ReadinessResult {
        val count = history.instrumentCompletions(INSTRUMENT_TYPE).size
        return ReadinessResult(isReady = count >= minimumCyclesForScoring, scoredCycles = count)
    }

    override fun runScoring(history: ClinicalHistory): ScoringResult =
        GreeneScoringResult(
            history.instrumentCompletions(INSTRUMENT_TYPE).map { completion ->
                GreeneCompletionScore(
                    date = completion.endDate,
                    result = GreeneScale.score(GreeneResponsesJson.decode(completion.itemResponsesJson)),
                )
            },
        )
}

/** One completed Greene questionnaire, scored.
 *
 * @property date The completion (recall-period end) date, ISO-8601.
 * @property result The Greene domain profile for that completion.
 */
data class GreeneCompletionScore(val date: String, val result: GreeneResult)

/** The Perimenopause module's output: each Greene completion scored, oldest first. */
data class GreeneScoringResult(val completions: List<GreeneCompletionScore>) : ScoringResult
