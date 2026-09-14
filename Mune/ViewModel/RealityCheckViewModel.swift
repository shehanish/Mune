//
//  RealityCheckViewModel.swift
//  Mune
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RealityCheckViewModel {
    var thought: String
    var answer: String = ""
    var statusMessage: String?
    var pastChecks: [RealityCheckEntry] = []

    init(thought: String = "") {
        self.thought = thought
    }

    var challenge: String {
        Self.challenge(for: thought)
    }

    var canSave: Bool {
        !thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadHistory(userID: String, context: ModelContext) {
        let currentUserID = userID
        let predicate = #Predicate<RealityCheckEntry> { entry in
            entry.userID == currentUserID
        }
        var descriptor = FetchDescriptor<RealityCheckEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        pastChecks = (try? context.fetch(descriptor)) ?? []
    }

    func save(userID: String, context: ModelContext) {
        guard canSave else {
            statusMessage = "Write the thought and a short answer first."
            return
        }

        let entry = RealityCheckEntry(
            userID: userID,
            thought: thought.trimmingCharacters(in: .whitespacesAndNewlines),
            challenge: challenge,
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(entry)
        do {
            try context.save()
            statusMessage = "Saved on this device."
            thought = ""
            answer = ""
            loadHistory(userID: userID, context: context)
        } catch {
            statusMessage = "I couldn’t save that just now. We can try again in a moment."
        }
    }

    static func challenge(for thought: String) -> String {
        let text = RecoveryMood.normalized(thought)

        if text.contains("perfect") || text.contains("never wrong") || text.contains("flawless") {
            return "What wasn’t working?"
        }
        if text.contains("never find") || text.contains("anyone like") || text.contains("no one else") {
            return "What is this thought protecting?"
        }
        if text.contains("the one") || text.contains("soulmate") {
            return "What need went unmet?"
        }
        if text.contains("my fault") || text.contains("i ruined") {
            return "What wasn’t yours to carry?"
        }
        if text.contains("they miss") || text.contains("come back") || text.contains("still love") {
            return "What if you didn’t need that answer today?"
        }
        return "What feels true, and what feels like the ache?"
    }
}
