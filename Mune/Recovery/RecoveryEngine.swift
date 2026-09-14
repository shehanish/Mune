//
//  RecoveryEngine.swift
//  Mune
//
//  Chooses one intervention from the user's current state.
//  The user should not have to pick a tool first.
//

import Foundation

nonisolated enum RecoveryMood {
    static let sad = "Sad"
    static let rumination = "Can't stop thinking"
    static let missing = "Missing them"
    static let angry = "Angry"
    static let lonely = "Lonely"
    static let contactUrge = "Want to contact them"
    static let anxious = "Anxious"
    static let okay = "I'm doing okay"
    static let happy = "Happy"
    static let excited = "Excited"
    static let grateful = "Grateful"
    static let hopeful = "Hopeful"
    static let calm = "Calm"

    static let checkInOptions = [
        happy, sad, calm, rumination, grateful, missing, excited,
        angry, hopeful, lonely, okay, contactUrge, anxious
    ]

    static func normalized(_ mood: String) -> String {
        mood
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
    }

    static func isContactUrge(_ mood: String) -> Bool {
        normalized(mood) == normalized(contactUrge)
    }

    static func isRumination(_ mood: String) -> Bool {
        normalized(mood) == normalized(rumination)
    }

    static func isMissing(_ mood: String) -> Bool {
        normalized(mood) == normalized(missing)
    }

    static func isSupportive(_ mood: String) -> Bool {
        switch normalized(mood) {
        case "i'm doing okay", "im doing okay", "okay",
             "happy", "excited", "grateful", "hopeful", "calm", "proud":
            return true
        default:
            return false
        }
    }

    static func isHeavy(_ mood: String) -> Bool {
        switch normalized(mood) {
        case "sad", "angry", "anxious", "lonely", "empty", "tired",
             "can't stop thinking", "cant stop thinking",
             "missing them", "want to contact them":
            return true
        default:
            return false
        }
    }

    static func weight(for mood: String) -> Int {
        if isSupportive(mood) { return 1 }
        if isHeavy(mood) { return -1 }
        return 0
    }
}

enum RecoveryDestination: Equatable {
    case urgeWave
    case contactUrge
    case realityCheck
    case calmSpace(CalmSpaceFocus? = nil)
    case chat
    case journal
    case journalExercise(String)
    case rebuild
    case progress
    case checkIn
}

enum RecoveryUrgency: Equatable {
    case acute
    case supportive
    case steady
}

struct RecoverySignals: Equatable {
    var now: Date
    var hour: Int
    var isLateNight: Bool
    var isEvening: Bool
    var healingDaysCount: Int?
    var hasCheckedInToday: Bool
    var todayMoods: [String]
    var todayNote: String
    var todayMoodScoreOutOfTen: Int?
    var nightCheckInCount: Int
    var usuallyStrugglesAtNight: Bool
    var contactUrgeCount: Int
    var hasContactUrgeToday: Bool
    var contactOftenFollowedByAnxiety: Bool
    var ruminationCount: Int
    var hasRuminationToday: Bool
    var missingCount: Int
    var hasMissingToday: Bool
    var heavyMoodCount: Int
    var checkInCount: Int
    var dominantMood: String?
}

struct RecoveryIntervention: Equatable {
    let headline: String
    let body: String
    let contextLine: String?
    let whyLine: String?
    let actionLabel: String
    let destination: RecoveryDestination
    let urgency: RecoveryUrgency
    let chatStarter: String?

    static let defaultCheckIn = RecoveryIntervention(
        headline: "Here’s one next step based on how you’re feeling.",
        body: "Take a second to notice where you are, then check in when you’re ready.",
        contextLine: nil,
        whyLine: nil,
        actionLabel: "Check in",
        destination: .checkIn,
        urgency: .supportive,
        chatStarter: nil
    )

    func withSignals(_ signals: RecoverySignals) -> RecoveryIntervention {
        RecoveryIntervention(
            headline: headline,
            body: body,
            contextLine: contextLine ?? RecoveryEngine.contextLine(from: signals),
            whyLine: whyLine ?? RecoveryEngine.whyLine(from: signals),
            actionLabel: actionLabel,
            destination: destination,
            urgency: urgency,
            chatStarter: chatStarter
        )
    }
}

enum RecoverySignalBuilder {
    private static let lookbackDays = 21

    static func make(
        now: Date = .now,
        calendar: Calendar = .current,
        entries: [MoodEntry],
        healingDaysCount: Int?
    ) -> RecoverySignals {
        let hour = calendar.component(.hour, from: now)
        let startOfToday = calendar.startOfDay(for: now)
        let todayEntries = entries.filter { $0.timestamp >= startOfToday }
        let todayMoods = todayEntries.flatMap(\.moods)
        let todayNote = todayEntries
            .compactMap { $0.notes?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let nightEntries = entries.filter { isNightHour(calendar.component(.hour, from: $0.timestamp)) }
        let contactEntries = entries.filter { hasContactUrge(in: $0) }
        let ruminationEntries = entries.filter { hasRumination(in: $0) }
        let missingEntries = entries.filter { hasMissing(in: $0) }
        let heavyCount = entries.reduce(0) { $0 + $1.moods.filter { RecoveryMood.isHeavy($0) }.count }

        var moodCounts: [String: Int] = [:]
        for mood in entries.flatMap(\.moods) {
            moodCounts[mood, default: 0] += 1
        }

        let nightRatio = entries.isEmpty ? 0 : Double(nightEntries.count) / Double(entries.count)
        let usuallyNights = nightEntries.count >= 3 || (entries.count >= 4 && nightRatio >= 0.35)

        return RecoverySignals(
            now: now,
            hour: hour,
            isLateNight: isNightHour(hour),
            isEvening: hour >= 17 && hour < 22,
            healingDaysCount: healingDaysCount,
            hasCheckedInToday: !todayEntries.isEmpty,
            todayMoods: todayMoods,
            todayNote: todayNote,
            todayMoodScoreOutOfTen: moodScoreOutOfTen(from: todayMoods),
            nightCheckInCount: nightEntries.count,
            usuallyStrugglesAtNight: usuallyNights,
            contactUrgeCount: contactEntries.count,
            hasContactUrgeToday: todayEntries.contains(where: { hasContactUrge(in: $0) }),
            contactOftenFollowedByAnxiety: contactOftenFollowedByAnxiety(in: entries, calendar: calendar),
            ruminationCount: ruminationEntries.count,
            hasRuminationToday: todayEntries.contains(where: { hasRumination(in: $0) }),
            missingCount: missingEntries.count,
            hasMissingToday: todayEntries.contains(where: { hasMissing(in: $0) }),
            heavyMoodCount: heavyCount,
            checkInCount: entries.count,
            dominantMood: moodCounts.max(by: { $0.value < $1.value })?.key
        )
    }

    static func lookbackStart(from now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -lookbackDays + 1, to: calendar.startOfDay(for: now)) ?? now
    }

    static func isNightHour(_ hour: Int) -> Bool {
        hour >= 22 || hour < 5
    }

    static func hasContactUrge(in entry: MoodEntry) -> Bool {
        entry.moods.contains(where: RecoveryMood.isContactUrge) || containsAny(entry.notes, phrases: contactPhrases)
    }

    static func hasRumination(in entry: MoodEntry) -> Bool {
        entry.moods.contains(where: RecoveryMood.isRumination) || containsAny(entry.notes, phrases: ruminationPhrases)
    }

    static func hasMissing(in entry: MoodEntry) -> Bool {
        entry.moods.contains(where: RecoveryMood.isMissing)
            || entry.moods.contains(where: { RecoveryMood.normalized($0) == "sad" })
            || containsAny(entry.notes, phrases: missingPhrases)
    }

    private static func moodScoreOutOfTen(from moods: [String]) -> Int? {
        guard !moods.isEmpty else { return nil }
        let mapped = moods.map { mood -> Int in
            if RecoveryMood.isContactUrge(mood) || RecoveryMood.isRumination(mood) {
                return 3
            }
            switch RecoveryMood.weight(for: mood) {
            case 1: return 7
            case -1: return 3
            default: return 5
            }
        }
        return Int((Double(mapped.reduce(0, +)) / Double(mapped.count)).rounded())
    }

    private static func contactOftenFollowedByAnxiety(in entries: [MoodEntry], calendar: Calendar) -> Bool {
        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        var followed = 0
        var contactMoments = 0

        for (index, entry) in sorted.enumerated() where hasContactUrge(in: entry) {
            contactMoments += 1
            let windowEnd = calendar.date(byAdding: .hour, value: 36, to: entry.timestamp) ?? entry.timestamp
            let later = sorted.dropFirst(index + 1).prefix { $0.timestamp <= windowEnd }
            if later.contains(where: { $0.moods.contains(where: { RecoveryMood.normalized($0) == "anxious" }) }) {
                followed += 1
            }
        }

        return contactMoments >= 2 && followed >= 1
    }

    private static func containsAny(_ text: String?, phrases: [String]) -> Bool {
        guard let text, !text.isEmpty else { return false }
        let haystack = RecoveryMood.normalized(text)
        return phrases.contains { haystack.contains($0) }
    }

    private static let contactPhrases = [
        "text my ex", "text her", "text him", "text them",
        "call my ex", "call her", "call him", "call them",
        "message my ex", "message her", "message him",
        "reach out", "want to contact", "wanted to contact", "wanted to text",
        "check their", "checking their", "checked their",
        "their instagram", "her instagram", "his instagram",
        "their story", "should i text", "should i call"
    ]

    private static let ruminationPhrases = [
        "can't stop thinking", "cant stop thinking", "can't stop",
        "overthinking", "obsessing", "keep thinking",
        "why didn't", "why won't they", "what if they"
    ]

    private static let missingPhrases = [
        "i miss", "missing them", "missing her", "missing him",
        "wish they", "wish she", "wish he"
    ]
}

enum RecoveryEngine {
    static func intervention(from signals: RecoverySignals) -> RecoveryIntervention {
        let chosen: RecoveryIntervention
        if let night = nightIntervention(from: signals) {
            chosen = night
        } else if let contact = contactUrgeIntervention(from: signals) {
            chosen = contact
        } else if let rumination = ruminationIntervention(from: signals) {
            chosen = rumination
        } else if let heavy = heavyFeelingIntervention(from: signals) {
            chosen = heavy
        } else if let early = earlyHealingIntervention(from: signals) {
            chosen = early
        } else if let steady = steadyIntervention(from: signals) {
            chosen = steady
        } else {
            chosen = defaultIntervention(from: signals)
        }
        return chosen.withSignals(signals)
    }

    static func whyLine(from signals: RecoverySignals) -> String? {
        let today = signals.todayMoods
        guard !today.isEmpty else {
            if !signals.todayNote.isEmpty {
                return "From the note you wrote today."
            }
            return nil
        }

        var unique: [String] = []
        for mood in today where !unique.contains(mood) {
            unique.append(mood)
        }
        if unique.count == 1 {
            return "You marked \(unique[0])."
        }
        if unique.count == 2 {
            return "You marked \(unique[0]) and \(unique[1])."
        }
        return "You marked \(unique[0]), \(unique[1]), and more."
    }

    static func contextLine(from signals: RecoverySignals) -> String? {
        var parts: [String] = []

        if let days = signals.healingDaysCount, days > 0 {
            parts.append(days == 1 ? "1 day without contact" : "\(days) days without contact")
        }

        if signals.usuallyStrugglesAtNight {
            parts.append("nights have been harder")
        }

        if signals.contactUrgeCount >= 2 {
            parts.append("contact urges have been showing up")
        } else if signals.contactOftenFollowedByAnxiety {
            parts.append("reaching out has raised anxiety")
        }

        if let score = signals.todayMoodScoreOutOfTen, score <= 4 {
            parts.append("today is landing low")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func nightIntervention(from signals: RecoverySignals) -> RecoveryIntervention? {
        guard signals.isLateNight else { return nil }

        let todayIsSteady = signals.hasCheckedInToday
            && signals.todayMoods.contains(where: RecoveryMood.isSupportive)
            && !signals.hasContactUrgeToday
            && !signals.hasRuminationToday
            && !signals.hasMissingToday

        let shouldSlowDown = signals.usuallyStrugglesAtNight
            || signals.contactUrgeCount > 0
            || signals.hasMissingToday
            || signals.hasContactUrgeToday
            || signals.hasRuminationToday
            || !signals.hasCheckedInToday
            || (signals.healingDaysCount.map { $0 <= 45 } ?? false)

        if todayIsSteady && !signals.usuallyStrugglesAtNight && signals.contactUrgeCount == 0 {
            return RecoveryIntervention(
                headline: "It’s late, and things feel quiet enough.",
                body: "Take a breath and notice how your body feels.",
                contextLine: nil,
                whyLine: nil,
                actionLabel: "Pause with me",
                destination: .contactUrge,
                urgency: .supportive,
                chatStarter: nil
            )
        }

        guard shouldSlowDown else { return nil }

        let hasContactPull = signals.hasContactUrgeToday || signals.contactUrgeCount > 0 || !signals.hasCheckedInToday

        return RecoveryIntervention(
            headline: "Nights can feel heavier.",
            body: "Pause for a moment. Notice what’s loud, and what can wait until morning.",
            contextLine: nil,
            whyLine: nil,
            actionLabel: hasContactPull ? "Slow down before you text" : "2 quiet minutes",
            destination: hasContactPull ? .contactUrge : .urgeWave,
            urgency: .acute,
            chatStarter: nil
        )
    }

    private static func contactUrgeIntervention(from signals: RecoverySignals) -> RecoveryIntervention? {
        guard signals.hasContactUrgeToday || (signals.contactUrgeCount >= 2 && signals.hasCheckedInToday == false) else {
            return nil
        }

        return RecoveryIntervention(
            headline: "The urge to reach out is here.",
            body: "Take a second with the urge. What is it hoping for?",
            contextLine: nil,
            whyLine: nil,
            actionLabel: "Slow down before you text",
            destination: .contactUrge,
            urgency: .acute,
            chatStarter: nil
        )
    }

    private static func ruminationIntervention(from signals: RecoverySignals) -> RecoveryIntervention? {
        guard signals.hasRuminationToday || (signals.ruminationCount >= 2 && signals.dominantIsRumination) else {
            return nil
        }

        return RecoveryIntervention(
            headline: "Your thoughts keep returning.",
            body: "You don’t have to fix the loop right now. Just notice it’s there.",
            contextLine: nil,
            whyLine: nil,
            actionLabel: "Try a Reality Check",
            destination: .realityCheck,
            urgency: .supportive,
            chatStarter: nil
        )
    }

    private static func heavyFeelingIntervention(from signals: RecoverySignals) -> RecoveryIntervention? {
        let todayHeavy = signals.todayMoods.filter(RecoveryMood.isHeavy)
        let focus = todayHeavy.first ?? signals.dominantMood
        guard signals.hasCheckedInToday, let focus, RecoveryMood.isHeavy(focus) else {
            return nil
        }

        if RecoveryMood.isMissing(focus) || RecoveryMood.normalized(focus) == "sad" {
            return RecoveryIntervention(
                headline: "Missing them is close today.",
                body: "Give that feeling a little room. What part of it feels most true right now?",
                contextLine: nil,
                whyLine: nil,
                actionLabel: "2 quiet minutes",
                destination: .urgeWave,
                urgency: .supportive,
                chatStarter: nil
            )
        }

        if RecoveryMood.normalized(focus) == "lonely" {
            return RecoveryIntervention(
                headline: "Loneliness is close today.",
                body: "What kind of company do you need right now, not just who?",
                contextLine: nil,
                whyLine: nil,
                actionLabel: "Write what you miss",
                destination: .journalExercise(RecoveryExerciseID.miss),
                urgency: .supportive,
                chatStarter: nil
            )
        }

        if RecoveryMood.normalized(focus) == "angry" {
            return RecoveryIntervention(
                headline: "Anger is here.",
                body: "Notice it without rushing to act. What is it protecting?",
                contextLine: nil,
                whyLine: nil,
                actionLabel: "Ground in Calm Space",
                destination: .calmSpace(.ground),
                urgency: .supportive,
                chatStarter: nil
            )
        }

        if RecoveryMood.normalized(focus) == "anxious" {
            return RecoveryIntervention(
                headline: "Your body feels a little on edge.",
                body: "Take a second to notice your breath before anything else.",
                contextLine: nil,
                whyLine: nil,
                actionLabel: "Breathe with me",
                destination: .calmSpace(.breathe),
                urgency: .supportive,
                chatStarter: nil
            )
        }

        return nil
    }

    private static func earlyHealingIntervention(from signals: RecoverySignals) -> RecoveryIntervention? {
        guard let days = signals.healingDaysCount, days > 0, days <= 21, !signals.hasCheckedInToday else {
            return nil
        }

        return RecoveryIntervention(
            headline: earlyDaysHeadline(days),
            body: "Take a moment to notice how this stretch feels in your body today.",
            contextLine: nil,
            whyLine: nil,
            actionLabel: "Check in",
            destination: .checkIn,
            urgency: .supportive,
            chatStarter: nil
        )
    }

    private static func steadyIntervention(from signals: RecoverySignals) -> RecoveryIntervention? {
        let todaySteady = signals.hasCheckedInToday && signals.todayMoods.contains(where: RecoveryMood.isSupportive)
        guard todaySteady, !signals.hasContactUrgeToday, !signals.hasRuminationToday else {
            return nil
        }

        return RecoveryIntervention(
            headline: "Today feels a little steadier.",
            body: "Think about what helped today, then take one small step if you like.",
            contextLine: nil,
            whyLine: nil,
            actionLabel: "Today’s rebuild step",
            destination: .rebuild,
            urgency: .steady,
            chatStarter: nil
        )
    }

    private static func defaultIntervention(from signals: RecoverySignals) -> RecoveryIntervention {
        if signals.isEvening {
            return RecoveryIntervention(
                headline: "Evenings can reopen the day.",
                body: "Pause and notice how tonight feels before you move on.",
                contextLine: nil,
                whyLine: nil,
                actionLabel: "Check in",
                destination: .checkIn,
                urgency: .supportive,
                chatStarter: nil
            )
        }

        return .defaultCheckIn
    }

    private static func earlyDaysHeadline(_ days: Int) -> String {
        if days == 1 {
            return "You’re on day one without contact. This stretch can feel like a lot."
        }
        return "You’re \(days) days without contact. Early days can feel tender."
    }
}

private extension RecoverySignals {
    var dominantIsRumination: Bool {
        guard let dominantMood else { return false }
        return RecoveryMood.isRumination(dominantMood)
    }
}
