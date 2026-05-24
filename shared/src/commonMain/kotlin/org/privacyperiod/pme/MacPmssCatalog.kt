// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pme

import org.privacyperiod.data.db.SymptomDefinitionsQueries

/**
 * The MAC-PMSS mood-chart items, expressed as universal `symptom_definitions`.
 *
 * The MAC-PMSS (Frey et al., 2022) pairs the DRSP premenstrual chart with a daily
 * mood chart that captures the *ongoing* symptoms of an underlying condition —
 * which is what makes PMDD-vs-PME differentiation possible. The DRSP items are
 * reused from [org.privacyperiod.pmdd.DrspCatalog]; this catalog adds only the
 * mood-chart items, tagged with their MAC-PMSS provenance.
 *
 * The validated MAC-PMSS instrument is not modified; obtaining permission for its
 * use is part of clinical sign-off, and the PME module stays gated until then.
 */
object MacPmssCatalog {
    /** Instrument name recorded as the provenance of every mood-chart item. */
    const val PROVENANCE: String = "MAC-PMSS"

    /** A symptom definition ready to seed into the universal catalog. */
    data class Spec(
        val id: String,
        val nameKey: String,
        val category: String,
        val severityScale: String,
        val provenanceItem: String,
    )

    /** The MAC-PMSS mood-chart items added on top of the reused DRSP items. */
    val definitions: List<Spec> =
        listOf(
            Spec("macpmss_overall_mood", "symptom.macpmss_overall_mood", "mood", "likert_5", "MAC-PMSS-mood-overall"),
            Spec("macpmss_anxiety_level", "symptom.macpmss_anxiety_level", "mood", "likert_5", "MAC-PMSS-mood-anxiety"),
            Spec("macpmss_energy_level", "symptom.macpmss_energy_level", "energy", "likert_5", "MAC-PMSS-mood-energy"),
            Spec(
                "macpmss_functional_capacity",
                "symptom.macpmss_functional_capacity",
                "functional",
                "likert_5",
                "MAC-PMSS-mood-function",
            ),
            Spec(
                "macpmss_mood_elevation",
                "symptom.macpmss_mood_elevation",
                "mood",
                "likert_5",
                "MAC-PMSS-mood-elevation",
            ),
            Spec(
                "macpmss_suicidal_ideation",
                "symptom.macpmss_suicidal_ideation",
                "mood",
                "likert_5",
                "MAC-PMSS-mood-si",
            ),
        )

    /** Seeds (or refreshes) the MAC-PMSS mood-chart definitions. Idempotent. */
    fun seedInto(queries: SymptomDefinitionsQueries) {
        for (definition in definitions) {
            queries.upsertSymptomDefinition(
                id = definition.id,
                name_key = definition.nameKey,
                category = definition.category,
                severity_scale = definition.severityScale,
                clinical_provenance = PROVENANCE,
                provenance_item = definition.provenanceItem,
                is_active = 1L,
            )
        }
    }
}
