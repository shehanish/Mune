//
//  RebuildViewModel.swift
//  Mune
//

import Foundation
import Observation
import SwiftData

struct RebuildShowUpDay: Identifiable, Hashable {
    let id: Date
    let weekdayLetter: String
    let didShowUp: Bool
    let isToday: Bool
}

@MainActor
@Observable
final class RebuildViewModel {
    private let context: ModelContext
    private let userID: String
    private let calendar: Calendar

    var completions: [RebuildGoal] = []
    var celebrationMessage: String?

    init(context: ModelContext, userID: String, calendar: Calendar = .current) {
        self.context = context
        self.userID = userID
        self.calendar = calendar
        load()
    }

    var completedToday: [RebuildGoal] {
        completions.filter { calendar.isDateInToday($0.date) && $0.isDone }
            .sorted { $0.date > $1.date }
    }

    var hasShownUpToday: Bool {
        !completedToday.isEmpty
    }

    var showedUpDaysThisWeek: Int {
        lastSevenDays.filter(\.didShowUp).count
    }

    /// Last 7 days ending today, oldest → newest.
    var lastSevenDays: [RebuildShowUpDay] {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "EEEEE"

        return (0..<7).compactMap { offset -> RebuildShowUpDay? in
            let daysBack = 6 - offset
            guard let day = calendar.date(byAdding: .day, value: -daysBack, to: today) else { return nil }
            return RebuildShowUpDay(
                id: day,
                weekdayLetter: formatter.string(from: day),
                didShowUp: showedUpDays.contains(day),
                isToday: daysBack == 0
            )
        }
    }

    /// Consecutive show-up days ending today (or yesterday if today is still empty).
    var currentStreak: Int {
        let today = calendar.startOfDay(for: Date())
        var cursor = today
        if !showedUpDays.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  showedUpDays.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        var streak = 0
        while showedUpDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var statusLine: String {
        if hasShownUpToday {
            if currentStreak > 1 {
                return "Today counts. \(currentStreak) days in a row."
            }
            return "Today counts."
        }
        if currentStreak > 0 {
            return "Not yet today. You’re on \(currentStreak) \(currentStreak == 1 ? "day" : "days") in a row."
        }
        if showedUpDaysThisWeek == 0 {
            return "Tap something below when you’ve done it."
        }
        return "Not yet today."
    }

    private var showedUpDays: Set<Date> {
        Set(
            completions
                .filter(\.isDone)
                .map { calendar.startOfDay(for: $0.date) }
        )
    }

    func isDoneToday(title: String, category: RebuildCategory) -> Bool {
        let today = calendar.startOfDay(for: Date())
        return completions.contains { goal in
            goal.title == title
                && goal.categoryRaw == category.rawValue
                && calendar.isDate(goal.date, inSameDayAs: today)
                && goal.isDone
        }
    }

    func toggle(title: String, category: RebuildCategory) {
        let today = calendar.startOfDay(for: Date())
        if let existing = completions.first(where: {
            $0.title == title
                && $0.categoryRaw == category.rawValue
                && calendar.isDate($0.date, inSameDayAs: today)
        }) {
            let willComplete = !existing.isDone
            existing.isDone = willComplete
            existing.date = today
            try? context.save()
            load()
            celebrationMessage = willComplete ? "Nice. \(title) counts. You showed up for yourself." : nil
        } else {
            context.insert(
                RebuildGoal(userID: userID, category: category, title: title, date: today, isDone: true)
            )
            try? context.save()
            load()
            celebrationMessage = "Nice. \(title) counts. You showed up for yourself."
        }
    }

    /// Reloads completions and clears session celebration so a new day starts with an empty pick list.
    func refreshForToday() {
        celebrationMessage = nil
        load()
    }

    func load() {
        let currentUserID = userID
        // Keep enough history for a meaningful streak without loading forever.
        let lookbackStart = calendar.date(
            byAdding: .day,
            value: -29,
            to: calendar.startOfDay(for: Date())
        ) ?? Date()
        let descriptor = FetchDescriptor<RebuildGoal>(
            predicate: #Predicate { $0.userID == currentUserID && $0.date >= lookbackStart },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        completions = (try? context.fetch(descriptor)) ?? []
    }
}
