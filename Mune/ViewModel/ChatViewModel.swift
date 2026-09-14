//
//  ChatViewModel.swift
//  Mune
//
//  Created by Shehani Hansika on 18.05.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {
    private let userName: String
    private let contextProvider: (() -> ChatInsightContext?)?

    private var displayName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : userName
    }

    var messages: [ChatMessage]
    var inputText: String = ""
    var isThinking: Bool = false
    private var pendingSeedMessage: String?
    private var hasConsumedSeedMessage = false

    private static let minimumReplyPause: TimeInterval = 1.8
    
    private let aiService: any AIInsightService
    
    init(aiService: any AIInsightService, userName: String, contextProvider: (() -> ChatInsightContext?)? = nil) {
        self.aiService = aiService
        self.userName = userName
        self.contextProvider = contextProvider
        let resolvedName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : userName
        self.messages = [
            ChatMessage(
                text: "Hi \(resolvedName). I’m here as a recovery coach. Not to replay the breakup, and not to get anyone back. What’s the loudest thing right now?",
                isUser: false,
                senderName: "Mune"
            )
        ]
    }
    
    func sendMessage() async {
        let text = inputText
        inputText = ""
        await sendMessage(text: text)
    }

    func startConversation(with text: String) async {
        queueConversationStarter(text)
    }

    func queueConversationStarter(_ text: String) {
        pendingSeedMessage = text
        hasConsumedSeedMessage = false
    }

    func sendPendingSeedMessageIfNeeded() async {
        guard !hasConsumedSeedMessage, let pendingSeedMessage else { return }
        hasConsumedSeedMessage = true
        self.pendingSeedMessage = nil
        messages.append(ChatMessage(text: pendingSeedMessage, isUser: false, senderName: "Mune"))
    }

    private func sendMessage(text: String) async {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(text: text, isUser: true, senderName: displayName))

        let crisisSignals = CrisisSupportDetector.detect(in: text)
        if !crisisSignals.isEmpty {
            messages.append(
                ChatMessage(
                    text: crisisSupportMessage(for: crisisSignals),
                    isUser: false,
                    senderName: "Mune",
                    kind: .crisisSupport(crisisSignals)
                )
            )
            // Do not send crisis content to the AI service.
            return
        }

        isThinking = true

        let conversation = messages
            .filter { if case .text = $0.kind { return true }; return $0.isUser }
            .map { (isUser: $0.isUser, text: $0.text) }
        let context = contextProvider?()
        let thinkingStarted = Date()

        do {
            let response = try await aiService.generateChatResponse(
                conversation: conversation,
                userName: displayName,
                context: context
            )
            await waitForCompanionPause(since: thinkingStarted)
            let parsed = CoachExerciseParser.split(response)
            let fallback = parsed.exercise ?? RecoveryExerciseCatalog.inferredCoachExercise(fromUserText: text)
            messages.append(ChatMessage(text: parsed.text, isUser: false, senderName: "Mune", exercise: fallback))
            isThinking = false
        } catch {
            await waitForCompanionPause(since: thinkingStarted)
            messages.append(ChatMessage(text: "I hit a small snag. When you're ready, we can try again.", isUser: false, senderName: "Mune"))
            isThinking = false
        }
    }

    /// Keep “thinking with you…” visible for a short beat so replies don’t feel instant.
    private func waitForCompanionPause(since started: Date) async {
        let elapsed = Date().timeIntervalSince(started)
        let remaining = Self.minimumReplyPause - elapsed
        guard remaining > 0 else { return }
        try? await Task.sleep(for: .seconds(remaining))
    }

    static let starterChips = [
        "I keep checking their profile",
        "I want to text them",
        "Tonight is hard"
    ]

    func applyStarterChip(_ text: String) {
        inputText = text
    }

    private func crisisSupportMessage(for signals: Set<CrisisSignal>) -> String {
        if signals.contains(.selfHarm), signals.contains(.harmToOthers) {
            return "Thank you for trusting me with this. Your safety matters so much. Please reach for real help using the options below. You don’t have to face this alone."
        }
        if signals.contains(.harmToOthers) {
            return "Those thoughts are serious, and you don’t have to carry them alone. Please use the options below for immediate help. People are ready for you."
        }
        return "Thank you for telling me. You deserve real, human support right now. Please use the options below. You’re not alone."
    }
}
