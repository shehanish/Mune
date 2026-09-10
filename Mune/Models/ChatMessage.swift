//
//  ChatMessage.swift
//  Mend
//
//  Created by Shehani Hansika on 18.05.26.
//

import Foundation

enum ChatMessageKind: Equatable {
    case text
    case crisisSupport(Set<CrisisSignal>)
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let senderName: String
    let kind: ChatMessageKind

    init(
        text: String,
        isUser: Bool,
        senderName: String,
        kind: ChatMessageKind = .text
    ) {
        self.text = text
        self.isUser = isUser
        self.senderName = senderName
        self.kind = kind
    }
}
