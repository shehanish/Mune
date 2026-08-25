//
//  ChatViewModel.swift
//  Mend
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
    
    private let aiService: any AIInsightService
    
    init(aiService: any AIInsightService, userName: String, contextProvider: (() -> ChatInsightContext?)? = nil) {
        self.aiService = aiService
        self.userName = userName
        self.contextProvider = contextProvider
        let resolvedName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : userName
        self.messages = [
            ChatMessage(
                text: "I'm right here with you, \(resolvedName). What's sitting on your heart?",
                isUser: false,
                senderName: "Mend"
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
        messages.append(ChatMessage(text: pendingSeedMessage, isUser: false, senderName: "Mend"))
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
                    senderName: "Mend",
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

        do {
            let response = try await aiService.generateChatResponse(
                conversation: conversation,
                userName: displayName,
                context: context
            )
            messages.append(ChatMessage(text: response, isUser: false, senderName: "Mend"))
            isThinking = false
        } catch {
            messages.append(ChatMessage(text: "I hit a small snag. When you're ready, we can try again.", isUser: false, senderName: "Mend"))
            isThinking = false
        }
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
