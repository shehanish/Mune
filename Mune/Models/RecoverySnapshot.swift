//
//  RecoverySnapshot.swift
//  Mune
//

import Foundation
import SwiftData

@Model
final class RecoverySnapshot {
    var userID: String
    var date: Date
    var painIntensity: Int
    var thoughtFrequency: Int
    var contactUrge: Int
    var sleepQuality: Int
    var loneliness: Int
    var senseOfSelf: Int

    init(
        userID: String,
        date: Date = .now,
        painIntensity: Int,
        thoughtFrequency: Int,
        contactUrge: Int,
        sleepQuality: Int,
        loneliness: Int,
        senseOfSelf: Int
    ) {
        self.userID = userID
        self.date = date
        self.painIntensity = painIntensity
        self.thoughtFrequency = thoughtFrequency
        self.contactUrge = contactUrge
        self.sleepQuality = sleepQuality
        self.loneliness = loneliness
        self.senseOfSelf = senseOfSelf
    }
}
