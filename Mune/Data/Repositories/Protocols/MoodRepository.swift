//
//  MoodRepository.swift
//  Mend
//
//  Created by Shehani Hansika on 09.05.26.
//

import Foundation

protocol MoodRepository {
    func addMoodEntry(userID: String, notes: String?, moods: [String], timestamp: Date) async throws
    func fetchMoodEntries(userID: String, from startDate: Date, to endDate: Date) async throws -> [MoodEntry]
    func fetchLatestMoodEntry(userID: String) async throws -> MoodEntry?
}
