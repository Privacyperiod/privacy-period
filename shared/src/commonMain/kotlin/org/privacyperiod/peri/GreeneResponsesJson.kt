// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.peri

/**
 * A minimal JSON codec for the Greene scale's item responses — a flat map of item
 * number → 0–3 score, stored in `instrument_completions.item_responses_json`.
 *
 * Deliberately tiny and dependency-free: the project has no JSON serializer yet,
 * and Greene's responses are a controlled, flat integer→integer map. When more
 * instruments land (EHP-30, Peri-SS) this should be replaced by a real serializer
 * (kotlinx.serialization). Decoding is defensive — malformed input yields an empty
 * map rather than throwing.
 */
object GreeneResponsesJson {
    /** Encodes the responses as a compact JSON object, keys in ascending order. */
    fun encode(responses: Map<Int, Int>): String =
        responses.entries
            .sortedBy { it.key }
            .joinToString(separator = ",", prefix = "{", postfix = "}") { "\"${it.key}\":${it.value}" }

    /** Decodes the JSON object back to a response map; unparseable input → empty. */
    fun decode(json: String): Map<Int, Int> {
        val body = json.trim().removeSurrounding("{", "}").trim()
        if (body.isEmpty()) return emptyMap()
        return body.split(",").mapNotNull { pair ->
            val parts = pair.split(":")
            if (parts.size != 2) return@mapNotNull null
            val key = parts[0].trim().trim('"').toIntOrNull() ?: return@mapNotNull null
            val value = parts[1].trim().toIntOrNull() ?: return@mapNotNull null
            key to value
        }.toMap()
    }
}
