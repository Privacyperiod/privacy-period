// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2026 Privacy Period Contributors

import Foundation
import Shared

#if DEMO
/// Demo-only seed data helpers. Compiled exclusively into Debug and Demo builds
/// (the `DEMO` flag is set for both); stripped from the App Store Release build
/// so no seeding API surface is present in production.
extension EncryptedStore {
    /// Replaces all user data with two cycles of sample DRSP entries (a clear luteal
    /// rise) plus the cycle starts that anchor them, so the pattern tracker can be
    /// previewed for testing and clinician review.
    func seedSampleData() {
        guard let repository else { return }
        deleteAllData()
        // Enroll every condition so the seeded demo shows the full home structure.
        setPremenstrual(enabled: true, families: ["anxiety"])
        setEnrolled(moduleId: "hmb", true)
        setEnrolled(moduleId: "perimenopause", true)
        setEnrolled(moduleId: "endometriosis", true)
        let calendar = Calendar.current
        let today = Date()
        // Two menses onsets, each fully surrounded by data so C-PASS can score the
        // cycle centred on it. The most recent (24 days ago) puts "today" at cycle
        // day ~25 — late luteal — so the in-progress cycle visibly shows the rise on
        // the landing-page reveal, not just the completed cycles.
        let onsetsDaysAgo = [52, 24]
        let referenceOnset = 24
        for daysAgo in onsetsDaysAgo {
            if let start = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                save(CycleDraft(startDate: start, endDate: nil, flow: "MEDIUM", notes: ""))
            }
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let cycleLength = 28
        let lutealStart = 19
        let baseSeverity = 2
        // 63 days of daily DRSP ratings scored by cycle day: a low follicular baseline
        // that rises through the luteal phase — a clear, cyclical premenstrual pattern
        // that repeats every cycle, including the one in progress.
        for daysAgo in 0...62 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let dateString = Self.isoDate(date)
            let cycleDay = ((referenceOnset - daysAgo) % cycleLength + cycleLength) % cycleLength + 1
            let score = cycleDay >= lutealStart ? min(6, baseSeverity + (cycleDay - lutealStart + 1)) : baseSeverity
            for item in 1...24 {
                writeSymptom(repository, "drsp_\(item)", Double(score), dateString, now)
            }
        }
        seedSampleMeals(calendar: calendar, today: today, now: now)
    }

    /// A meal to seed in the demo: a type, a time, and an optional neutral note.
    private struct MealSample {
        let type: String
        let time: String
        let what: String?
    }

    /// Seeds a sprinkling of meals across the recent window so the baseline meal
    /// markers (everyday context for the mood pattern) are visible in the demo.
    /// Neutral notes only — never calories, portions, or judgement.
    private func seedSampleMeals(calendar: Calendar, today: Date, now: Int64) {
        guard let database else { return }
        let samples = [
            MealSample(type: "breakfast", time: "08:00", what: "oatmeal and coffee"),
            MealSample(type: "lunch", time: "12:30", what: "sandwich and fruit"),
            MealSample(type: "dinner", time: "19:00", what: nil)
        ]
        // Most days carry a couple of meals; the gaps keep it realistic, not a streak.
        for daysAgo in 0...30 where daysAgo % 3 != 2 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let dateString = Self.isoDate(date)
            // Vary which meals appear per day so the markers aren't a uniform block.
            for (index, sample) in samples.enumerated() where (daysAgo + index) % 2 == 0 {
                database.mealLogEntriesQueries.insertMealLogEntry(
                    id: UUID().uuidString,
                    meal_date: dateString,
                    meal_time: sample.time,
                    meal_type: sample.type,
                    note: sample.what,
                    created_at: now
                )
            }
        }
    }
}
#endif
