//
//  SwiftDataJournalRepository.swift
//  Mend
//
//  Created by Shehani Hansika on 07.07.26.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataJournalRepository: JournalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func addJournalEntry(
        userID: String,
        moods: [String],
        moodNote: String?,
        journalText: String,
        transcript: String?,
        gratitudeOne: String,
        gratitudeTwo: String,
        gratitudeThree: String,
        timestamp: Date = .now
    ) async throws {
        let entry = JournalEntry(
            userID: userID,
            timestamp: timestamp,
            moods: moods.isEmpty ? nil : moods,
            moodNote: moodNote,
            journalText: journalText,
            transcript: transcript,
            gratitudeOne: gratitudeOne,
            gratitudeTwo: gratitudeTwo,
            gratitudeThree: gratitudeThree
        )

        context.insert(entry)
        try context.save()
    }
}