//
//  JournalEntry.swift
//  Mend
//
//  Created by Shehani Hansika on 07.07.26.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    var userID: String
    var timestamp: Date
    var moods: [String]?
    var moodNote: String?
    var journalText: String
    var transcript: String?
    var gratitudeOne: String
    var gratitudeTwo: String
    var gratitudeThree: String

    init(
        userID: String,
        timestamp: Date = .now,
        moods: [String]? = nil,
        moodNote: String? = nil,
        journalText: String,
        transcript: String? = nil,
        gratitudeOne: String,
        gratitudeTwo: String,
        gratitudeThree: String
    ) {
        self.userID = userID
        self.timestamp = timestamp
        self.moods = moods
        self.moodNote = moodNote
        self.journalText = journalText
        self.transcript = transcript
        self.gratitudeOne = gratitudeOne
        self.gratitudeTwo = gratitudeTwo
        self.gratitudeThree = gratitudeThree
    }
}