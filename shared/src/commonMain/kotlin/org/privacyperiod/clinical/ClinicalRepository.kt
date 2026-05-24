// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.clinical

import org.privacyperiod.data.db.Cycle_entries
import org.privacyperiod.data.db.PrivacyPeriodDatabase
import org.privacyperiod.data.db.Symptom_entries
import org.privacyperiod.pmdd.DrspCatalog
import org.privacyperiod.pme.MacPmssCatalog

/**
 * The single read/write gateway between clinical modules and the universal data
 * layer. Modules go through [ClinicalHistory] (produced by [history]) for reads
 * and through this repository for writes; they never touch the database directly.
 *
 * @property database The encrypted SQLDelight database.
 */
class ClinicalRepository(private val database: PrivacyPeriodDatabase) {
    /**
     * Seeds (or refreshes) the built-in clinical catalog — the validated
     * instrument items expressed as universal symptom definitions. Idempotent;
     * safe to call on every launch.
     *
     * Declared to throw so the caller can degrade gracefully (rather than crash
     * at launch) if the database is in an unexpected state — for example a stale
     * schema on a developer device. On a fresh install it always succeeds.
     */
    @Throws(Throwable::class)
    fun seedCatalog() {
        DrspCatalog.seedInto(database.symptomDefinitionsQueries)
        MacPmssCatalog.seedInto(database.symptomDefinitionsQueries)
    }

    /**
     * Writes a symptom rating, replacing any existing rating for the same symptom
     * and date (one rating per symptom per day).
     */
    fun saveSymptomEntry(entry: SymptomEntry) {
        database.symptomEntriesQueries.upsertSymptomEntry(
            id = entry.id,
            symptom_id = entry.symptomId,
            date = entry.date,
            severity = entry.severity,
            cycle_id = entry.cycleId,
            cycle_phase = entry.cyclePhase,
            cycle_day = entry.cycleDay?.toLong(),
            same_day_logged = if (entry.sameDayLogged) 1L else 0L,
            notes = entry.notes,
            created_at = entry.createdAt,
        )
    }

    /** Returns a read-only snapshot of the user's clinical data for scoring. */
    fun history(): ClinicalHistory = DatabaseClinicalHistory(database)
}

/** [ClinicalHistory] backed by the database; reads are lazy and cached per instance. */
private class DatabaseClinicalHistory(
    private val database: PrivacyPeriodDatabase,
) : ClinicalHistory {
    override val cycles: List<Cycle> by lazy {
        database.cycleEntriesQueries.selectAllCycleEntries().executeAsList().map { it.toCycle() }
    }

    private val allSymptomEntries: List<SymptomEntry> by lazy {
        database.symptomEntriesQueries.selectAllSymptomEntries().executeAsList().map { it.toSymptomEntry() }
    }

    override fun symptomEntries(symptomIds: Set<String>): List<SymptomEntry> =
        allSymptomEntries.filter { it.symptomId in symptomIds }

    override fun sameDaySymptomEntries(symptomIds: Set<String>): List<SymptomEntry> =
        symptomEntries(symptomIds).filter { it.sameDayLogged }
}

private fun Cycle_entries.toCycle(): Cycle =
    Cycle(
        id = id,
        startDate = start_date,
        endDate = end_date,
        flowIntensity = flow_intensity,
        notes = notes,
        predictedNext = predicted_next,
        createdAt = created_at,
    )

private fun Symptom_entries.toSymptomEntry(): SymptomEntry =
    SymptomEntry(
        id = id,
        symptomId = symptom_id,
        date = date,
        severity = severity,
        cycleId = cycle_id,
        cyclePhase = cycle_phase,
        cycleDay = cycle_day?.toInt(),
        sameDayLogged = same_day_logged != 0L,
        notes = notes,
        createdAt = created_at,
    )
