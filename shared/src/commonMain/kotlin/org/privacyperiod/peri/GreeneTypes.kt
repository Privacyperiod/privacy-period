// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

/**
 * The six symptom domains of the Greene Climacteric Scale, with the 1-based item
 * numbers that belong to each. The standard 21-item structure: Anxiety (1–6),
 * Depression (7–11), Somatic (12–18), Vasomotor (19–20), and Sexual (21).
 * "Psychological" is the combined Anxiety + Depression total, derived separately.
 */
@Suppress("MagicNumber") // The item ranges are the Greene scale's fixed, published structure.
enum class GreeneSubscale(val items: IntRange) {
    ANXIETY(1..6),
    DEPRESSION(7..11),
    SOMATIC(12..18),
    VASOMOTOR(19..20),
    SEXUAL(21..21),
}

/**
 * A Greene Climacteric Scale result: a symptom-severity *profile*, not a
 * diagnosis. The scale has no diagnostic cutoff; it reports per-domain severity.
 *
 * @property subscales Each domain's summed score (each item 0–3).
 * @property psychological Combined Anxiety + Depression score.
 * @property total Sum across all items.
 * @property isComplete Whether all 21 items were answered.
 */
data class GreeneResult(
    val subscales: Map<GreeneSubscale, Int>,
    val psychological: Int,
    val total: Int,
    val isComplete: Boolean,
) {
    /** Per-domain accessors, for callers (e.g. the iOS layer) that avoid map lookups. */
    val anxiety: Int get() = subscales[GreeneSubscale.ANXIETY] ?: 0
    val depression: Int get() = subscales[GreeneSubscale.DEPRESSION] ?: 0
    val somatic: Int get() = subscales[GreeneSubscale.SOMATIC] ?: 0
    val vasomotor: Int get() = subscales[GreeneSubscale.VASOMOTOR] ?: 0
    val sexual: Int get() = subscales[GreeneSubscale.SEXUAL] ?: 0
}
