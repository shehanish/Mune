//
//  SwiftDataMoodRepository.swift
//  Mend
//
//  Created by Shehani Hansika on 09.05.26.
//


import Foundation
import SwiftData

/// SwiftData-backed implementation of MoodRepository.
import Foundation
import SwiftData

@MainActor
final class SwiftDataMoodRepository: MoodRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addMoodEntry(
        userID: String,
        notes: String?,
        moods: [String],
        timestamp: Date = .now
    ) async throws {
        let entry = MoodEntry(
            userID: userID,
            timestamp: timestamp,
            moods: moods,
            notes: notes
        )
        context.insert(entry)
        try context.save()
    }

    func fetchMoodEntries(userID: String, from startDate: Date, to endDate: Date) async throws -> [MoodEntry] {
        // Predicate filters rows in the persistent store.
        let predicate = #Predicate<MoodEntry> { entry in
            entry.userID == userID &&
            entry.timestamp >= startDate &&
            entry.timestamp <= endDate
        }

        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    func fetchLatestMoodEntry(userID: String) async throws -> MoodEntry? {
        let predicate = #Predicate<MoodEntry> { entry in
            entry.userID == userID
        }

        var descriptor = FetchDescriptor<MoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }
}
