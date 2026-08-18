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
                text: "I'm here while you get through this, \(resolvedName). What's on your mind?",
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

        // Add user message
        messages.append(ChatMessage(text: text, isUser: true, senderName: displayName))
        isThinking = true
        
        let conversation = messages.map { (isUser: $0.isUser, text: $0.text) }
        let context = contextProvider?()
        
        do {
            let response = try await aiService.generateChatResponse(conversation: conversation, userName: displayName, context: context)
            messages.append(ChatMessage(text: response, isUser: false, senderName: "Mend"))
            isThinking = false
        } catch {
            messages.append(ChatMessage(text: "Something went wrong. Please try again.", isUser: false, senderName: "Mend"))
            isThinking = false
        }
    }
}
