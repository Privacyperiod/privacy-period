// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.fail

/**
 * Proves that [CpassScorer] produces output identical to the authoritative
 * reference implementation, the R package `lasy/cpass` (CC BY 4.0).
 *
 * The fixtures are generated directly from the reference:
 *  - `PMDD_data.csv` is the package's bundled example dataset (20 subjects).
 *  - `subject_truth.csv` and `cycle_truth.csv` are the subject- and cycle-level
 *    diagnoses produced by running `cpass()` on that dataset.
 *
 * The test runs our Kotlin scorer over the same input and asserts equality on
 * every scored field for all 37 cycles and 20 subjects. The human-readable
 * record of this comparison lives in `docs/cpass-conformance.md`.
 *
 * The scorer is pure `commonMain` code, so passing here on the JVM proves the
 * same logic that runs on iOS.
 */
class CpassConformanceTest {
    @Test
    fun cycleLevelDiagnosesMatchReference() {
        val result = CpassScorer.score(loadObservations())
        val byKey = result.cycles.associateBy { it.subject to it.cycle }
        val rows = readCsv("cpass/cycle_truth.csv")
        assertEquals(37, rows.size, "expected 37 reference cycles")

        for (row in rows) {
            val subject = row.getValue("subject").toInt()
            val cycle = row.getValue("cycle").toInt()
            val where = "subject $subject cycle $cycle"
            val actual = byKey[subject to cycle] ?: fail("no cycle result for $where")

            assertEquals(row.bool("included"), actual.included, "$where: included")
            assertEquals(
                row.int("n_DSM5_domains_meeting_PME_criteria"),
                actual.nDomainsMeetingPme,
                "$where: n domains PME",
            )
            assertEquals(
                row.int("n_DSM5_domains_meeting_PMDD_criteria"),
                actual.nDomainsMeetingPmdd,
                "$where: n domains PMDD",
            )
            assertEquals(row.boolOrNull("PME"), actual.pme, "$where: PME")
            assertEquals(row.boolOrNull("DSM5_A"), actual.dsm5A, "$where: DSM5_A")
            assertEquals(row.boolOrNull("DSM5_B"), actual.dsm5B, "$where: DSM5_B")
            assertEquals(
                cycleClassification(row.getValue("diagnosis")),
                actual.classification,
                "$where: diagnosis",
            )
        }
    }

    @Test
    fun subjectLevelDiagnosesMatchReference() {
        val result = CpassScorer.score(loadObservations())
        val bySubject = result.subjects.associateBy { it.subject }
        val rows = readCsv("cpass/subject_truth.csv")
        assertEquals(20, rows.size, "expected 20 reference subjects")

        for (row in rows) {
            val subject = row.getValue("subject").toInt()
            val where = "subject $subject"
            val actual = bySubject[subject] ?: fail("no subject result for $where")

            assertEquals(row.int("Ncycles_tot"), actual.nCyclesTotal, "$where: total cycles")
            assertEquals(row.int("Ncycles"), actual.nCyclesIncluded, "$where: included cycles")
            assertEquals(row.intOrNull("N_PMDD"), actual.nPmddCycles, "$where: N_PMDD")
            assertEquals(row.intOrNull("N_MRMD"), actual.nMrmdCycles, "$where: N_MRMD")
            assertEquals(row.intOrNull("N_PME"), actual.nPmeCycles, "$where: N_PME")
            assertEquals(row.boolOrNull("PMDD"), actual.meetsPmdd, "$where: PMDD")
            assertEquals(row.boolOrNull("MRMD"), actual.meetsMrmd, "$where: MRMD")
            assertEquals(row.boolOrNull("PME"), actual.meetsPme, "$where: PME")
            assertEquals(
                subjectClassification(row.getValue("dxcat")),
                actual.classification,
                "$where: dxcat",
            )
            val expectedAvg = row.getValue("avgdsm5crit").toDouble()
            assertEquals(expectedAvg, actual.avgDomainsMeetingPmdd, 1e-9, "$where: avg domains PMDD")
        }
    }

    // --- fixture loading ---------------------------------------------------------

    private fun loadObservations(): List<DrspObservation> =
        readCsv("cpass/PMDD_data.csv").map { row ->
            DrspObservation(
                subject = row.int("subject"),
                cycle = row.int("cycle"),
                day = row.int("day"),
                item = row.int("item"),
                score = row.intOrNull("drsp_score"),
            )
        }

    /** A parsed CSV row, keyed by (unquoted) header name. */
    private class Row(private val values: Map<String, String>) {
        fun getValue(key: String): String = values.getValue(key)

        /** Null for an empty cell or the R "NA" sentinel. */
        private fun raw(key: String): String? = values.getValue(key).takeUnless { it.isEmpty() || it == "NA" }

        fun int(key: String): Int = getValue(key).toInt()

        fun intOrNull(key: String): Int? = raw(key)?.toInt()

        fun bool(key: String): Boolean = getValue(key) == "TRUE"

        fun boolOrNull(key: String): Boolean? = raw(key)?.let { it == "TRUE" }
    }

    private fun readCsv(resource: String): List<Row> {
        val text =
            javaClass.classLoader.getResourceAsStream(resource)?.bufferedReader()?.readText()
                ?: error("missing test resource: $resource")
        val lines = text.trim().lines()
        val header = splitCsv(lines.first())
        return lines.drop(1).map { line ->
            val cells = splitCsv(line)
            Row(header.zip(cells).toMap())
        }
    }

    /** Splits a simple CSV line and strips surrounding quotes. None of the fixture
     *  values contain embedded commas, so a plain split is sufficient. */
    private fun splitCsv(line: String): List<String> = line.split(",").map { it.trim().removeSurrounding("\"") }

    private fun cycleClassification(diagnosis: String): CycleClassification? =
        when (diagnosis) {
            "NA" -> null
            "no diagnosis" -> CycleClassification.NO_DIAGNOSIS
            "PME" -> CycleClassification.PME
            "MRMD" -> CycleClassification.MRMD
            "PMDD" -> CycleClassification.PMDD
            else -> fail("unexpected diagnosis: $diagnosis")
        }

    private fun subjectClassification(dxcat: String): SubjectClassification? {
        if (dxcat == "NA" || dxcat.isEmpty()) return null
        // dxcat: 0 no diagnosis, 1 MRMD, 2 PMDD, 3 PME — matching the enum order.
        val classification = SubjectClassification.entries[dxcat.toInt()]
        assertNotNull(classification)
        return classification
    }
}
