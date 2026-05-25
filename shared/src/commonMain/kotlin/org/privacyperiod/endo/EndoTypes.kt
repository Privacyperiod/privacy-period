// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.endo

/**
 * The patient-reported inputs to the endometriosis screening score (Chauvet et
 * al., 2021). VAS values are 0–10; null means not answered (treated as below
 * threshold). Risk factors are booleans the user self-reports.
 *
 * @property familyHistory A first-degree relative with endometriosis.
 * @property primaryInfertility Difficulty conceiving with no prior pregnancy.
 * @property bmiUnder22 Body-mass index below 22.
 * @property cyclesUnder28 Regular menstrual cycles shorter than 28 days.
 * @property vasDysmenorrhea Period-pain intensity (0–10).
 * @property vasDeepDyspareunia Deep pain-with-sex intensity (0–10).
 * @property vasGiSymptoms Gastrointestinal-symptom intensity (0–10).
 * @property vasUrinarySymptoms Urinary-symptom intensity (0–10).
 */
data class EndoScreenInputs(
    val familyHistory: Boolean,
    val primaryInfertility: Boolean,
    val bmiUnder22: Boolean,
    val cyclesUnder28: Boolean,
    val vasDysmenorrhea: Int?,
    val vasDeepDyspareunia: Int?,
    val vasGiSymptoms: Int?,
    val vasUrinarySymptoms: Int?,
)

/** The screening risk band for an endometriosis score. Never a diagnosis. */
enum class EndoRiskLevel { LOW, INTERMEDIATE, HIGH, VERY_HIGH }

/**
 * The endometriosis screening result: both published scores and their risk bands.
 *
 * @property briefScore Chauvet "Score 2", the 5-item score (no pelvic-pain
 *   self-assessment beyond dysmenorrhea).
 * @property briefRisk The risk band for [briefScore].
 * @property extendedScore Chauvet "Score 1", the 8-item score.
 * @property extendedRisk The risk band for [extendedScore].
 */
data class EndoScreenResult(
    val briefScore: Int,
    val briefRisk: EndoRiskLevel,
    val extendedScore: Int,
    val extendedRisk: EndoRiskLevel,
)
