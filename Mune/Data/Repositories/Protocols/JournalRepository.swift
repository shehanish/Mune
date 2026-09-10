//
//  JournalRepository.swift
//  Mend
//
//  Created by Shehani Hansika on 07.07.26.
//

import Foundation

protocol JournalRepository {
    func addJournalEntry(
        userID: String,
        moods: [String],
        moodNote: String?,
        journalText: String,
        transcript: String?,
        gratitudeOne: String,
        gratitudeTwo: String,
        gratitudeThree: String,
        timestamp: Date
    ) async throws
}