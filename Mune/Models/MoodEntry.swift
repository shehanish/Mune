//
//  MoodEntry.swift
//  Mend
//
//  Created by Shehani Hansika on 07.05.26.
//


import Foundation
import SwiftData

@Model
final class MoodEntry {
    var userID: String
    var timestamp: Date
    var moods: [String]

    // NEW
    var notes: String?

    init(userID: String, timestamp: Date = .now, moods: [String], notes: String? = nil) {
        self.userID = userID
        self.timestamp = timestamp
        self.moods = moods
        self.notes = notes
    }
}
