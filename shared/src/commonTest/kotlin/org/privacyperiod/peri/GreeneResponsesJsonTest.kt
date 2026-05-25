// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Tests the minimal Greene item-responses JSON codec. */
class GreeneResponsesJsonTest {
    @Test
    fun roundTripsAResponseMap() {
        val responses = mapOf(1 to 3, 2 to 0, 21 to 2)
        val decoded = GreeneResponsesJson.decode(GreeneResponsesJson.encode(responses))
        assertEquals(responses, decoded)
    }

    @Test
    fun encodesKeysInAscendingOrder() {
        assertEquals("{\"1\":3,\"2\":1,\"10\":2}", GreeneResponsesJson.encode(mapOf(10 to 2, 1 to 3, 2 to 1)))
    }

    @Test
    fun emptyMapEncodesAndDecodes() {
        assertEquals("{}", GreeneResponsesJson.encode(emptyMap()))
        assertTrue(GreeneResponsesJson.decode("{}").isEmpty())
        assertTrue(GreeneResponsesJson.decode("").isEmpty())
    }

    @Test
    fun malformedInputDecodesToEmptyOrSkips() {
        assertTrue(GreeneResponsesJson.decode("not json").isEmpty())
        assertEquals(mapOf(1 to 3), GreeneResponsesJson.decode("{\"1\":3,\"bad\"}"))
    }
}
