//
//  DataExportService.swift
//  Mune
//

import Foundation
import SwiftData
import UIKit

enum DataExportService {
    @MainActor
    static func exportText(userID: String, userName: String, context: ModelContext) -> URL? {
        let moods = (try? context.fetch(
            FetchDescriptor<MoodEntry>(
                predicate: #Predicate { $0.userID == userID },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        )) ?? []

        let journals = (try? context.fetch(
            FetchDescriptor<JournalEntry>(
                predicate: #Predicate { $0.userID == userID },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        )) ?? []

        let realityChecks = (try? context.fetch(
            FetchDescriptor<RealityCheckEntry>(
                predicate: #Predicate { $0.userID == userID },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        )) ?? []

        let rebuildGoals = (try? context.fetch(
            FetchDescriptor<RebuildGoal>(
                predicate: #Predicate { $0.userID == userID },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )) ?? []

        let snapshots = (try? context.fetch(
            FetchDescriptor<RecoverySnapshot>(
                predicate: #Predicate { $0.userID == userID },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        )) ?? []

        let formatter = ISO8601DateFormatter()
        var lines: [String] = []
        lines.append("Mune data export")
        lines.append("Name: \(userName.isEmpty ? "Friend" : userName)")
        lines.append("Exported: \(formatter.string(from: Date()))")
        lines.append("")

        lines.append("## Check-ins")
        if moods.isEmpty {
            lines.append("(none)")
        } else {
            for entry in moods {
                lines.append("- \(formatter.string(from: entry.timestamp))")
                if !entry.moods.isEmpty {
                    lines.append("  Moods: \(entry.moods.joined(separator: ", "))")
                }
                if let notes = entry.notes, !notes.isEmpty {
                    lines.append("  Note: \(notes)")
                }
            }
        }

        lines.append("")
        lines.append("## Journal")
        if journals.isEmpty {
            lines.append("(none)")
        } else {
            for entry in journals {
                lines.append("- \(formatter.string(from: entry.timestamp))")
                if !entry.journalText.isEmpty {
                    lines.append("  \(entry.journalText)")
                }
                if let transcript = entry.transcript, !transcript.isEmpty {
                    lines.append("  Transcript: \(transcript)")
                }
                let gratitudes = [entry.gratitudeOne, entry.gratitudeTwo, entry.gratitudeThree]
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !gratitudes.isEmpty {
                    lines.append("  Gratitudes: \(gratitudes.joined(separator: " · "))")
                }
            }
        }

        lines.append("")
        lines.append("## Reality checks")
        if realityChecks.isEmpty {
            lines.append("(none)")
        } else {
            for entry in realityChecks {
                lines.append("- \(formatter.string(from: entry.timestamp))")
                lines.append("  Thought: \(entry.thought)")
                lines.append("  Challenge: \(entry.challenge)")
                lines.append("  Answer: \(entry.answer)")
            }
        }

        lines.append("")
        lines.append("## Rebuild show-ups")
        if rebuildGoals.isEmpty {
            lines.append("(none)")
        } else {
            for goal in rebuildGoals where goal.isDone {
                lines.append("- \(formatter.string(from: goal.date)): \(goal.title) (\(goal.categoryRaw))")
            }
        }

        lines.append("")
        lines.append("## Recovery snapshots")
        if snapshots.isEmpty {
            lines.append("(none)")
        } else {
            for shot in snapshots {
                lines.append("- \(formatter.string(from: shot.date)): pain \(shot.painIntensity), urge \(shot.contactUrge), sleep \(shot.sleepQuality), self \(shot.senseOfSelf)")
            }
        }

        let text = lines.joined(separator: "\n")
        let filename = "Mune-export-\(Int(Date().timeIntervalSince1970)).txt"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            MuneLog.debug("[DataExportService] write failed: \(error)")
            return nil
        }
    }
}
