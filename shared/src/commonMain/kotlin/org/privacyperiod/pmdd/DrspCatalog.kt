// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import org.privacyperiod.data.db.SymptomDefinitionsQueries

/**
 * The 24 DRSP items expressed as universal `symptom_definitions`, so the PMDD
 * module (and any other that reuses the DRSP, e.g. PME's MAC-PMSS) consumes them
 * from the shared clinical layer rather than a private table.
 *
 * Each definition carries its provenance — `clinical_provenance = "DRSP"` and the
 * exact `provenance_item` — so the clinical layer ties out, in public, to the
 * published instrument (see `docs/clinical-provenance.md`). The stable id is
 * `drsp_<n>`; the domain/category and item set come from [DrspItem], which is the
 * conformance-verified dictionary.
 */
object DrspCatalog {
    /** Instrument name recorded as the provenance of every DRSP definition. */
    const val PROVENANCE: String = "DRSP"

    /** Severity scale shared by all DRSP items (1 = not at all … 6 = extreme). */
    const val SEVERITY_SCALE: String = "drsp_6"

    /** Prefix of every DRSP symptom's stable id, e.g. `drsp_1`. */
    const val ID_PREFIX: String = "drsp_"

    /** A symptom definition ready to be seeded into the universal catalog. */
    data class Spec(
        val id: String,
        val nameKey: String,
        val category: String,
        val severityScale: String,
        val clinicalProvenance: String,
        val provenanceItem: String,
    )

    /** The 24 DRSP items as universal symptom definitions. */
    val definitions: List<Spec> =
        DrspItem.entries.map { item ->
            Spec(
                id = stableId(item.number),
                nameKey = "symptom.drsp_${item.number}",
                category = universalCategory(item.domain),
                severityScale = SEVERITY_SCALE,
                clinicalProvenance = PROVENANCE,
                provenanceItem = "DRSP-${item.number}",
            )
        }

    /** The stable symptom id for a DRSP item number, e.g. 1 → `drsp_1`. */
    fun stableId(itemNumber: Int): String = "$ID_PREFIX$itemNumber"

    /** The DRSP item number for a stable id, or null if it is not a DRSP id. */
    fun itemNumber(symptomId: String): Int? =
        if (symptomId.startsWith(ID_PREFIX)) symptomId.removePrefix(ID_PREFIX).toIntOrNull() else null

    /**
     * Seeds (or refreshes) the 24 DRSP definitions in the catalog. Idempotent —
     * re-running updates existing rows in place by their stable id.
     */
    fun seedInto(queries: SymptomDefinitionsQueries) {
        for (definition in definitions) {
            queries.upsertSymptomDefinition(
                id = definition.id,
                name_key = definition.nameKey,
                category = definition.category,
                severity_scale = definition.severityScale,
                clinical_provenance = definition.clinicalProvenance,
                provenance_item = definition.provenanceItem,
                is_active = 1L,
            )
        }
    }

    /** Maps a DSM-5 domain to the universal `symptom_definitions.category` vocabulary. */
    private fun universalCategory(domain: Dsm5Domain): String =
        when (domain) {
            Dsm5Domain.DEPRESSION, Dsm5Domain.ANXIETY, Dsm5Domain.MOOD_LABILITY, Dsm5Domain.ANGER -> "mood"
            Dsm5Domain.INTEREST, Dsm5Domain.APPETITE -> "behavioral"
            Dsm5Domain.CONCENTRATION -> "cognitive"
            Dsm5Domain.LETHARGY, Dsm5Domain.SLEEP -> "energy"
            Dsm5Domain.OVERWHELM, Dsm5Domain.INTERFERENCE -> "functional"
            Dsm5Domain.PHYSICAL -> "physical"
        }
}
