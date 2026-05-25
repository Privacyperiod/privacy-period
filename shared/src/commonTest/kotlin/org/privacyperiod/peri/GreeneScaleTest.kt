// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Tests the clean-room Greene Climacteric Scale scorer against its published
 * 21-item, six-domain structure and 0–3 item range.
 */
class GreeneScaleTest {
    private fun allItems(value: Int): Map<Int, Int> = (1..GreeneScale.ITEM_COUNT).associateWith { value }

    @Test
    fun emptyScoresZeroAndIncomplete() {
        val result = GreeneScale.score(emptyMap())
        assertEquals(0, result.total)
        assertEquals(0, result.psychological)
        assertFalse(result.isComplete)
    }

    @Test
    fun maxScoreSumsPerDomain() {
        // Every item at 3: domain totals are 3 × item count.
        val result = GreeneScale.score(allItems(3))
        assertTrue(result.isComplete)
        assertEquals(18, result.subscales.getValue(GreeneSubscale.ANXIETY)) // 6 × 3
        assertEquals(15, result.subscales.getValue(GreeneSubscale.DEPRESSION)) // 5 × 3
        assertEquals(21, result.subscales.getValue(GreeneSubscale.SOMATIC)) // 7 × 3
        assertEquals(6, result.subscales.getValue(GreeneSubscale.VASOMOTOR)) // 2 × 3
        assertEquals(3, result.subscales.getValue(GreeneSubscale.SEXUAL)) // 1 × 3
        assertEquals(33, result.psychological) // 18 + 15
        assertEquals(63, result.total) // 21 × 3
    }

    @Test
    fun domainsSumOnlyTheirOwnItems() {
        // Only the vasomotor items (19, 20) rated.
        val result = GreeneScale.score(mapOf(19 to 3, 20 to 2))
        assertEquals(5, result.subscales.getValue(GreeneSubscale.VASOMOTOR))
        assertEquals(0, result.subscales.getValue(GreeneSubscale.ANXIETY))
        assertEquals(5, result.total)
        assertFalse(result.isComplete)
    }

    @Test
    fun outOfRangeScoresAreClamped() {
        val result = GreeneScale.score(mapOf(1 to 9, 2 to -4))
        assertEquals(3, result.subscales.getValue(GreeneSubscale.ANXIETY)) // 3 (clamped) + 0 (clamped)
    }

    @Test
    fun allItemsCoveredByExactlyOneDomain() {
        val covered = GreeneSubscale.entries.flatMap { it.items }.toSet()
        assertEquals((1..GreeneScale.ITEM_COUNT).toSet(), covered)
        assertEquals(GreeneScale.ITEM_COUNT, GreeneSubscale.entries.sumOf { it.items.count() })
    }
}
