//
//  RealityCheckEntry.swift
//  Mune
//

import Foundation
import SwiftData

@Model
final class RealityCheckEntry {
    var userID: String
    var timestamp: Date
    var thought: String
    var challenge: String
    var answer: String

    init(
        userID: String,
        timestamp: Date = .now,
        thought: String,
        challenge: String,
        answer: String
    ) {
        self.userID = userID
        self.timestamp = timestamp
        self.thought = thought
        self.challenge = challenge
        self.answer = answer
    }
}
