//
//  RecoveryProgressViewModel.swift
//  Mune
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RecoveryProgressViewModel {
    private let context: ModelContext
    private let userID: String
    private let calendar: Calendar

    var painIntensity: Double = 5
    var thoughtFrequency: Double = 3
    var contactUrge: Double = 5
    var sleepQuality: Double = 2
    var loneliness: Double = 2
    var senseOfSelf: Double = 2
    var snapshots: [RecoverySnapshot] = []
    var statusMessage: String?

    init(context: ModelContext, userID: String, calendar: Calendar = .current) {
        self.context = context
        self.userID = userID
        self.calendar = calendar
        load()
        if let latest = snapshots.first {
            painIntensity = Double(latest.painIntensity)
            thoughtFrequency = Double(latest.thoughtFrequency)
            contactUrge = Double(latest.contactUrge)
            sleepQuality = Double(latest.sleepQuality)
            loneliness = Double(latest.loneliness)
            senseOfSelf = Double(latest.senseOfSelf)
        }
    }

    var latest: RecoverySnapshot? { snapshots.first }

    var previous: RecoverySnapshot? {
        snapshots.count > 1 ? snapshots[1] : nil
    }

    var hasCheckedInThisWeek: Bool {
        guard let latest else { return false }
        let weekStart = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) ?? Date()
        return latest.date >= weekStart
    }

    var summaryLine: String {
        guard let latest else {
            return "When you’re ready, a quiet weekly check-in can show progress that days-since can’t."
        }
        if let previous, latest.painIntensity < previous.painIntensity || latest.contactUrge < previous.contactUrge {
            return "You’re making progress. The numbers are moving, even if today still hurts."
        }
        return "Showing up to measure this is already progress."
    }

    func save() {
        let snapshot = RecoverySnapshot(
            userID: userID,
            painIntensity: Int(painIntensity.rounded()),
            thoughtFrequency: Int(thoughtFrequency.rounded()),
            contactUrge: Int(contactUrge.rounded()),
            sleepQuality: Int(sleepQuality.rounded()),
            loneliness: Int(loneliness.rounded()),
            senseOfSelf: Int(senseOfSelf.rounded())
        )
        context.insert(snapshot)
        do {
            try context.save()
            load()
            statusMessage = "Snapshot saved. A bad day doesn’t erase your progress."
        } catch {
            statusMessage = "I couldn’t save that just now."
        }
    }

    func load() {
        let currentUserID = userID
        let descriptor = FetchDescriptor<RecoverySnapshot>(
            predicate: #Predicate { $0.userID == currentUserID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        snapshots = (try? context.fetch(descriptor)) ?? []
    }

    static func thoughtLabel(for value: Int) -> String {
        switch value {
        case ...1: return "Occasionally"
        case 2: return "A few times a day"
        case 3: return "Several times a day"
        case 4: return "Often"
        default: return "Constantly"
        }
    }

    static func sleepLabel(for value: Int) -> String {
        switch value {
        case ...1: return "Poor"
        case 2: return "Improving"
        default: return "Normal"
        }
    }

    static func lonelinessLabel(for value: Int) -> String {
        switch value {
        case ...1: return "Low"
        case 2: return "Moderate"
        default: return "High"
        }
    }

    static func selfLabel(for value: Int) -> String {
        switch value {
        case ...1: return "I don’t know who I am"
        case 2: return "I’m figuring myself out"
        default: return "I’m okay being me"
        }
    }
}
