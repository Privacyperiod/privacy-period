// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

package org.privacyperiod.pmdd

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Unit tests for [CpassScorer] using small, hand-built cases that document each
 * C-PASS rule and its edge cases. End-to-end agreement with the reference
 * implementation is covered separately by the conformance suite.
 */
class CpassScorerTest {
    // Seven pre-menstrual days (-1..-7) and seven post-menstrual days (4..10).
    private fun itemObservations(
        item: Int,
        pre: List<Int>,
        post: List<Int>,
        subject: Int = 1,
        cycle: Int = 1,
    ): List<DrspObservation> {
        val preObs = pre.mapIndexed { i, s -> DrspObservation(subject, cycle, -1 - i, item, s) }
        val postObs = post.mapIndexed { i, s -> DrspObservation(subject, cycle, 4 + i, item, s) }
        return preObs + postObs
    }

    private fun CpassResult.item(item: Int) = items.single { it.item == item }

    private fun CpassResult.cycle(subject: Int = 1, cycle: Int = 1) =
        cycles.single { it.subject == subject && it.cycle == cycle }

    private fun CpassResult.subject(subject: Int = 1) = subjects.single { it.subject == subject }

    @Test
    fun phaseWindowsFollowCpassConvention() {
        assertEquals(CyclePhase.PRE_MENSES, CyclePhase.ofDay(-7))
        assertEquals(CyclePhase.PRE_MENSES, CyclePhase.ofDay(-1))
        assertEquals(CyclePhase.MENSES, CyclePhase.ofDay(1))
        assertEquals(CyclePhase.MENSES, CyclePhase.ofDay(3))
        assertEquals(CyclePhase.POST_MENSES, CyclePhase.ofDay(4))
        assertEquals(CyclePhase.POST_MENSES, CyclePhase.ofDay(10))
        assertEquals(CyclePhase.PERI_OVULATION, CyclePhase.ofDay(11))
        assertEquals(CyclePhase.PERI_OVULATION, CyclePhase.ofDay(-8))
    }

    @Test
    fun dictionaryExcludesHeadacheAndInterferenceFromDomainScoring() {
        assertTrue(DrspItem.fromNumber(19).countsTowardDomainDiagnosis)
        assertTrue(!DrspItem.fromNumber(20).countsTowardDomainDiagnosis) // headache
        for (interference in 22..24) {
            assertTrue(!DrspItem.fromNumber(interference).countsTowardDomainDiagnosis)
        }
        assertEquals(Dsm5Domain.DEPRESSION, DrspItem.fromNumber(1).domain)
        assertEquals(SymptomCategory.CORE_EMOTIONAL, DrspItem.fromNumber(1).domain.category)
        assertEquals(SymptomCategory.SECONDARY, DrspItem.fromNumber(9).domain.category)
    }

    @Test
    fun itemMeetsPmddWhenHighPreClearsPostWithLargeChange() {
        // Pre at the ceiling (6) for a full week; post at the floor (1): clearance.
        val result = CpassScorer.score(itemObservations(item = 1, pre = List(7) { 6 }, post = List(7) { 1 }))
        val item = result.item(1)
        assertTrue(item.hasEnoughObservations)
        assertEquals(6, item.maxSevPre)
        assertEquals(7, item.nDaysHighScore)
        assertEquals(1, item.maxSevPost)
        // range = 6 - 1 = 5; change = (6 - 1) / 5 * 100 = 100%.
        assertEquals(100.0, item.percentChange)
        assertEquals(true, item.meetsPmddCriteria)
        assertEquals(true, item.meetsPmeCriteria)
    }

    @Test
    fun itemMeetsPmeButNotPmddWithoutClearance() {
        // Post stays high (4): the symptom does not clear, so PME but not PMDD.
        val result = CpassScorer.score(itemObservations(item = 1, pre = List(7) { 6 }, post = List(7) { 4 }))
        val item = result.item(1)
        assertEquals(4, item.maxSevPost)
        assertEquals(true, item.meetsPmeCriteria)
        assertEquals(false, item.meetsPmddCriteria)
    }

    @Test
    fun itemFailsWhenChangeBelowThreshold() {
        // One ceiling score on another item pins the subject range to 6 - 1 = 5,
        // so item 1's change = (4 - 3) / 5 * 100 = 20% < 30%.
        val result =
            CpassScorer.score(
                itemObservations(item = 1, pre = List(7) { 4 }, post = List(7) { 3 }) +
                    DrspObservation(subject = 1, cycle = 1, day = -1, item = 2, score = 6),
            )
        val item = result.item(1)
        assertTrue(item.maxSevPre != null && item.maxSevPre >= 4)
        assertEquals(20.0, item.percentChange)
        assertEquals(false, item.meetsPmddCriteria)
    }

    @Test
    fun itemCriteriaAreUnknownWithTooFewObservations() {
        // Only three pre-menstrual days: below the four-day minimum.
        val result = CpassScorer.score(itemObservations(item = 1, pre = List(3) { 6 }, post = List(7) { 1 }))
        val item = result.item(1)
        assertTrue(!item.hasEnoughObservations)
        assertNull(item.meetsPmddCriteria)
        assertNull(item.meetsPmeCriteria)
    }

    @Test
    fun cycleIsExcludedWithoutEnoughDaysInBothPhases() {
        // Three post-menstrual days only -> cycle not included.
        val result = CpassScorer.score(itemObservations(item = 1, pre = List(7) { 6 }, post = List(3) { 1 }))
        assertTrue(!result.cycle().included)
    }

    @Test
    fun cycleIsMrmdWhenCoreDomainMeetsButFewerThanFiveDomains() {
        // Two core-emotional domains meet criteria (items 1 and 4); nothing else.
        val obs =
            itemObservations(1, List(7) { 6 }, List(7) { 1 }) +
                itemObservations(4, List(7) { 6 }, List(7) { 1 })
        val cycle = CpassScorer.score(obs).cycle()
        assertTrue(cycle.included)
        assertEquals(true, cycle.dsm5A)
        assertEquals(false, cycle.dsm5B)
        assertEquals(2, cycle.nDomainsMeetingPmdd)
        assertEquals(CycleClassification.MRMD, cycle.classification)
    }

    @Test
    fun cycleIsPmddWhenCoreDomainAndFiveOrMoreDomainsMeet() {
        // Four core domains (1,4,5,7) plus two secondary (9,10) = six domains.
        val meeting = listOf(1, 4, 5, 7, 9, 10)
        val obs = meeting.flatMap { itemObservations(it, List(7) { 6 }, List(7) { 1 }) }
        val cycle = CpassScorer.score(obs).cycle()
        assertEquals(true, cycle.dsm5A)
        assertEquals(true, cycle.dsm5B)
        assertEquals(6, cycle.nDomainsMeetingPmdd)
        assertEquals(CycleClassification.PMDD, cycle.classification)
    }

    @Test
    fun cycleIsNoDiagnosisWhenSymptomsStayLow() {
        val obs =
            itemObservations(1, List(7) { 1 }, List(7) { 1 }) +
                itemObservations(4, List(7) { 2 }, List(7) { 2 })
        val cycle = CpassScorer.score(obs).cycle()
        assertTrue(cycle.included)
        assertEquals(false, cycle.dsm5A)
        assertEquals(CycleClassification.NO_DIAGNOSIS, cycle.classification)
    }

    @Test
    fun subjectClassificationIsUndefinedWithASingleCycle() {
        val meeting = listOf(1, 4, 5, 7, 9, 10)
        val obs = meeting.flatMap { itemObservations(it, List(7) { 6 }, List(7) { 1 }) }
        val subject = CpassScorer.score(obs).subject()
        assertEquals(1, subject.nCyclesIncluded)
        assertNull(subject.classification)
        assertNull(subject.meetsPmdd)
    }

    @Test
    fun subjectIsPmddWhenMajorityOfCyclesArePmdd() {
        val meeting = listOf(1, 4, 5, 7, 9, 10)
        val obs =
            (1..2).flatMap { cycle ->
                meeting.flatMap { itemObservations(it, List(7) { 6 }, List(7) { 1 }, cycle = cycle) }
            }
        val subject = CpassScorer.score(obs).subject()
        assertEquals(2, subject.nCyclesIncluded)
        assertEquals(2, subject.nPmddCycles)
        assertEquals(true, subject.meetsPmdd)
        assertEquals(SubjectClassification.PMDD, subject.classification)
    }

    @Test
    fun emptyInputProducesEmptyResult() {
        val result = CpassScorer.score(emptyList())
        assertTrue(result.items.isEmpty())
        assertTrue(result.cycles.isEmpty())
        assertTrue(result.subjects.isEmpty())
    }
}
