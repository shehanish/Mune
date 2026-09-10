//
//  AIInsightService.swift
//  Mend
//
//  Created by Shehani Hansika on 12.05.26.
//


import Foundation

protocol AIInsightService {
    func generateMoodInsight(from input: MoodInsightInput, userName: String) async throws -> String
    func generateChatResponse(conversation: [(isUser: Bool, text: String)], userName: String, context: ChatInsightContext?) async throws -> String
}

struct ChatInsightContext {
    let weeklySummaryLine: String?
    let weeklyHelpfulPatternText: String?
    let weeklyWarningText: String?
    let latestCheckInText: String?
    let healingTrendText: String?
    let healingSupportMessage: String?
    let healingThemes: [String]
    let recentMoodHighlights: [String]
    let recentJournalHighlights: [String]

    var isEmpty: Bool {
        weeklySummaryLine == nil &&
        weeklyHelpfulPatternText == nil &&
        weeklyWarningText == nil &&
        latestCheckInText == nil &&
        healingTrendText == nil &&
        healingSupportMessage == nil &&
        healingThemes.isEmpty &&
        recentMoodHighlights.isEmpty &&
        recentJournalHighlights.isEmpty
    }

    var promptText: String {
        var lines: [String] = []

        if let weeklySummaryLine, !weeklySummaryLine.isEmpty {
            lines.append("Weekly summary: \(weeklySummaryLine)")
        }

        if let weeklyHelpfulPatternText, !weeklyHelpfulPatternText.isEmpty {
            lines.append("What helped most: \(weeklyHelpfulPatternText)")
        }

        if let weeklyWarningText, !weeklyWarningText.isEmpty {
            lines.append("Gentle warning: \(weeklyWarningText)")
        }

        if let latestCheckInText, !latestCheckInText.isEmpty {
            lines.append("Latest check-in: \(latestCheckInText)")
        }

        if let healingTrendText, !healingTrendText.isEmpty {
            lines.append("Healing trend: \(healingTrendText)")
        }

        if let healingSupportMessage, !healingSupportMessage.isEmpty {
            lines.append("Support suggestion: \(healingSupportMessage)")
        }

        if !healingThemes.isEmpty {
            lines.append("Recent themes: \(healingThemes.joined(separator: ", "))")
        }

        if !recentMoodHighlights.isEmpty {
            lines.append("Recent mood check-ins: \(recentMoodHighlights.joined(separator: " | "))")
        }

        if !recentJournalHighlights.isEmpty {
            lines.append("Recent journal notes: \(recentJournalHighlights.joined(separator: " | "))")
        }

        return lines.joined(separator: "\n")
    }
}