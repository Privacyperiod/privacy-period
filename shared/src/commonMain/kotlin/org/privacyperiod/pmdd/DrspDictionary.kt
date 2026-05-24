// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

/*
 * The clinical structure of the Daily Record of Severity of Problems (DRSP) as
 * used by the Carolina Premenstrual Assessment Scoring System (C-PASS).
 *
 * The 24 DRSP items, their grouping into 11 DSM-5 symptom domains, and the
 * symptom categories below follow the C-PASS procedure published in
 * Eisenlohr-Moul et al. (2017, American Journal of Psychiatry) and the
 * reference implementation `lasy/cpass` (the `dsm5_dict` table, CC BY 4.0).
 * This file encodes only that structure — item numbers, domains, and
 * categories — which is the scoring specification. The validated, human-facing
 * DRSP item wording is a separate licensed instrument (Endicott et al.) and is
 * intentionally not stored here; the UI references items by number through
 * localized strings.
 *
 * Nothing in this module produces a diagnosis for the user. See CpassScorer
 * for how these structures are scored and the strict no-diagnosis framing.
 */

/**
 * How a DSM-5 symptom domain contributes to the C-PASS diagnosis.
 *
 * Core emotional symptoms are required for DSM-5 criterion A; together with the
 * secondary symptoms they count toward criterion B. Interference is recorded but
 * does not contribute to the domain-level diagnosis.
 */
enum class SymptomCategory {
    /** DSM-5 criterion A symptoms: depression, anxiety, mood lability, anger. */
    CORE_EMOTIONAL,

    /** Additional DSM-5 symptom domains that count toward criterion B. */
    SECONDARY,

    /** Functional interference; recorded but excluded from domain scoring. */
    INTERFERENCE,
}

/**
 * One of the DSM-5 symptom domains that DRSP items roll up into.
 *
 * @property category Whether the domain is core-emotional, secondary, or
 *   interference, per the C-PASS procedure.
 */
enum class Dsm5Domain(val category: SymptomCategory) {
    DEPRESSION(SymptomCategory.CORE_EMOTIONAL),
    ANXIETY(SymptomCategory.CORE_EMOTIONAL),
    MOOD_LABILITY(SymptomCategory.CORE_EMOTIONAL),
    ANGER(SymptomCategory.CORE_EMOTIONAL),
    INTEREST(SymptomCategory.SECONDARY),
    CONCENTRATION(SymptomCategory.SECONDARY),
    LETHARGY(SymptomCategory.SECONDARY),
    APPETITE(SymptomCategory.SECONDARY),
    SLEEP(SymptomCategory.SECONDARY),
    OVERWHELM(SymptomCategory.SECONDARY),
    PHYSICAL(SymptomCategory.SECONDARY),
    INTERFERENCE(SymptomCategory.INTERFERENCE),
}

/**
 * A single DRSP item, declared in DRSP order (DRSP1 first) so its [number]
 * follows from its position.
 *
 * @property domain The DSM-5 symptom domain the item belongs to.
 * @property countsTowardDomainDiagnosis Whether the item contributes to its
 *   domain's diagnosis. The C-PASS domain-level step excludes item 20 (headache)
 *   and the three interference items (22–24); those are still recorded but do not
 *   determine whether a domain meets criteria.
 */
enum class DrspItem(
    val domain: Dsm5Domain,
    val countsTowardDomainDiagnosis: Boolean,
) {
    DRSP1(Dsm5Domain.DEPRESSION, true),
    DRSP2(Dsm5Domain.DEPRESSION, true),
    DRSP3(Dsm5Domain.DEPRESSION, true),
    DRSP4(Dsm5Domain.ANXIETY, true),
    DRSP5(Dsm5Domain.MOOD_LABILITY, true),
    DRSP6(Dsm5Domain.MOOD_LABILITY, true),
    DRSP7(Dsm5Domain.ANGER, true),
    DRSP8(Dsm5Domain.ANGER, true),
    DRSP9(Dsm5Domain.INTEREST, true),
    DRSP10(Dsm5Domain.CONCENTRATION, true),
    DRSP11(Dsm5Domain.LETHARGY, true),
    DRSP12(Dsm5Domain.APPETITE, true),
    DRSP13(Dsm5Domain.APPETITE, true),
    DRSP14(Dsm5Domain.SLEEP, true),
    DRSP15(Dsm5Domain.SLEEP, true),
    DRSP16(Dsm5Domain.OVERWHELM, true),
    DRSP17(Dsm5Domain.OVERWHELM, true),
    DRSP18(Dsm5Domain.PHYSICAL, true),
    DRSP19(Dsm5Domain.PHYSICAL, true),
    DRSP20(Dsm5Domain.PHYSICAL, false),
    DRSP21(Dsm5Domain.PHYSICAL, true),
    DRSP22(Dsm5Domain.INTERFERENCE, false),
    DRSP23(Dsm5Domain.INTERFERENCE, false),
    DRSP24(Dsm5Domain.INTERFERENCE, false),
    ;

    /** The item's DRSP number, 1–24, derived from its declaration order. */
    val number: Int get() = ordinal + 1

    companion object {
        /** The lowest valid DRSP severity score (not at all / minimal). */
        const val MIN_SCORE: Int = 1

        /** The highest valid DRSP severity score (extreme). */
        const val MAX_SCORE: Int = 6

        private val byNumber: Map<Int, DrspItem> = entries.associateBy { it.number }

        /**
         * Returns the [DrspItem] with the given DRSP [number].
         *
         * @throws IllegalArgumentException if [number] is not in 1–24.
         */
        fun fromNumber(number: Int): DrspItem =
            byNumber[number]
                ?: throw IllegalArgumentException("DRSP item number must be in 1..24, was $number")
    }
}
