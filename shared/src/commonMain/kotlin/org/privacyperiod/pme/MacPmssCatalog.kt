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

    /**
     * The MAC-PMSS mood-chart items added on top of the reused DRSP items.
     *
     * Each item is a single-direction *severity* construct so the shared rating
     * control reads coherently (none → severe). Mood is captured as its two poles
     * — a depressed pole and an elevated/racing pole — because MAC-PMSS targets
     * premenstrual exacerbation of mood disorders (bipolar *and* depressive), and
     * a one-pole scale cannot represent the elevated side.
     *
     * These ids/labels are a provisional placeholder: the validated MAC-PMSS item
     * wording, anchors, and definitions are a licensed asset dropped in at
     * sign-off (see `instrument-licensing.md`). `definitionScale` records which
     * anchor set a clinician sees in the tap-to-define modal.
     */
    val definitions: List<Spec> =
        listOf(
            Spec(
                "macpmss_depressed_mood",
                "symptom.macpmss_depressed_mood",
                "mood",
                "likert_5",
                "MAC-PMSS-mood-depressed",
            ),
            Spec(
                "macpmss_mood_elevation",
                "symptom.macpmss_mood_elevation",
                "mood",
                "likert_5",
                "MAC-PMSS-mood-elevation",
            ),
            Spec("macpmss_anxiety", "symptom.macpmss_anxiety", "mood", "likert_5", "MAC-PMSS-mood-anxiety"),
            Spec("macpmss_low_energy", "symptom.macpmss_low_energy", "energy", "likert_5", "MAC-PMSS-mood-energy"),
            Spec(
                "macpmss_functional_impairment",
                "symptom.macpmss_functional_impairment",
                "functional",
                "impairment_5",
                "MAC-PMSS-mood-function",
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
