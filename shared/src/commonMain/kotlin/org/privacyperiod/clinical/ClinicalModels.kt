// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.clinical

// Domain models and the read-only history view that clinical modules consume.
// Modules depend on these plain types, never on the generated SQLDelight rows, so
// storage and clinical logic stay decoupled (modules are manifests, not storage).

/** A menstrual cycle the user has logged. Dates are ISO-8601 (YYYY-MM-DD). */
data class Cycle(
    val id: String,
    val startDate: String,
    val endDate: String?,
    val flowIntensity: String,
    val notes: String?,
    val predictedNext: String?,
    val createdAt: Long,
)

/**
 * A single clinical symptom rating on one day.
 *
 * @property symptomId The stable `symptom_definitions` id (e.g. "drsp_1").
 * @property severity Severity in the context of the symptom's scale.
 * @property sameDayLogged True only if logged on the day it describes; backdated
 *   entries are excluded from same-day-only scoring.
 */
data class SymptomEntry(
    val id: String,
    val symptomId: String,
    val date: String,
    val severity: Double,
    val cycleId: String?,
    val cyclePhase: String?,
    val cycleDay: Int?,
    val sameDayLogged: Boolean,
    val notes: String?,
    val createdAt: Long,
)

/**
 * A read-only view of the user's clinical data, scoped to what a module needs.
 *
 * Accessors are added here as modules require them; today the implemented
 * surface (cycles and symptom entries) is what the PMDD module consumes.
 */
interface ClinicalHistory {
    /** All logged cycles, oldest first by start date. */
    val cycles: List<Cycle>

    /** All entries for any of [symptomIds], oldest first by date. */
    fun symptomEntries(symptomIds: Set<String>): List<SymptomEntry>

    /** As [symptomEntries] but only same-day (prospective) entries. */
    fun sameDaySymptomEntries(symptomIds: Set<String>): List<SymptomEntry>

    /** All logged menstrual-flow events (for PBAC / heavy-bleeding scoring). */
    fun flowEvents(): List<FlowEvent>
}

/**
 * A single menstrual-flow event — a product change, clot, or flooding episode —
 * consumed by the Heavy Menstrual Bleeding module's PBAC scoring.
 *
 * @property flowType pad, tampon, cup, disc, period_underwear, clot, or flooding.
 * @property saturation Product saturation (light/moderate/heavy/soaked) or null.
 * @property clotSize Clot size (small/large) or null.
 * @property measuredMl Directly measured volume in millilitres (cups/discs) or null.
 * @property pbacPoints Precomputed PBAC points, or null to score from the fields.
 */
data class FlowEvent(
    val id: String,
    val cycleId: String,
    val eventDate: String,
    val eventTime: String?,
    val flowType: String,
    val saturation: String?,
    val clotSize: String?,
    val measuredMl: Double?,
    val pbacPoints: Int?,
    val createdAt: Long,
)
