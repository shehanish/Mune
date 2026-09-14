//
//  RebuildGoal.swift
//  Mune
//

import Foundation
import SwiftData

enum RebuildCategory: String, CaseIterable, Identifiable {
    case body = "Body"
    case mind = "Mind"
    case people = "People"
    case selfCare = "Self"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .body: return "figure.walk"
        case .mind: return "book"
        case .people: return "person.2"
        case .selfCare: return "sparkles"
        }
    }

    var suggestions: [String] {
        switch self {
        case .body:
            return [
                "10-min walk",
                "Stretch for one song",
                "Drink water",
                "Go to bed on time",
                "Eat a real meal"
            ]
        case .mind:
            return [
                "Read 10 pages",
                "Write 3 journal lines",
                "2-minute breathe",
                "Learn one new thing",
                "Put the phone down 20 min"
            ]
        case .people:
            return [
                "Text a friend",
                "Call someone safe",
                "Sit with family a bit",
                "Make a small plan with someone"
            ]
        case .selfCare:
            return [
                "15 min on a hobby",
                "Do one thing just for you",
                "Tidy one small corner",
                "Play music that feels like you",
                "Try something you’ve wanted"
            ]
        }
    }
}

@Model
final class RebuildGoal {
    var userID: String
    var categoryRaw: String
    var title: String
    var date: Date
    var isDone: Bool

    var category: RebuildCategory {
        RebuildCategory(rawValue: categoryRaw) ?? .selfCare
    }

    init(
        userID: String,
        category: RebuildCategory,
        title: String,
        date: Date = .now,
        isDone: Bool = false
    ) {
        self.userID = userID
        self.categoryRaw = category.rawValue
        self.title = title
        self.date = date
        self.isDone = isDone
    }
}
