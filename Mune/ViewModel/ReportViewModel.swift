//
//  ReportViewModel.swift
//  Mend
//
//  Created by Shehani Hansika on 11.05.26.
//


import Foundation
import Observation

@MainActor
@Observable
final class ReportViewModel {
    private let moodRepo: any MoodRepository
    private let userID: String
    private let calendar: Calendar

    // Presentation state
    var weeklyMoodCounts: [MoodCount] = []
    var isLoading: Bool = false
    var lastError: String?

    init(
        moodRepo: any MoodRepository,
        userID: String,
        calendar: Calendar = .current
    ) {
        self.moodRepo = moodRepo
        self.userID = userID
        self.calendar = calendar
    }

    /// Loads last 7 days (including today) and produces mood totals.
    func loadWeekly() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -6, to: end)! // 7 days inclusive

            let entries = try await moodRepo.fetchMoodEntries(
                userID: userID,
                from: start,
                to: end
            )

            // Flatten moods from each entry and count them
            var counts: [String: Int] = [:]
            for entry in entries {
                for mood in entry.moods {
                    counts[mood, default: 0] += 1
                }
            }

            // Convert to chart-friendly array (sorted)
            weeklyMoodCounts = counts
                .map { MoodCount(mood: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }

            lastError = nil
        } catch {
            lastError = String(describing: error)
            weeklyMoodCounts = []
        }
    }
}