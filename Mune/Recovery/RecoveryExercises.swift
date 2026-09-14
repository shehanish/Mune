//
//  RecoveryExercises.swift
//  Mune
//

import Foundation

enum RecoveryExerciseID {
    static let miss = "miss"
    static let whatHappened = "what-happened"
    static let learned = "learned"
    static let notWorking = "not-working"
    static let needs = "needs"
    static let patterns = "patterns"
    static let besides = "besides"
    static let before = "who-before"
    static let become = "who-become"
    static let unsent = "unsent-message"
}

struct GuidedJournalField: Identifiable, Hashable {
    let id: String
    let prompt: String
}

struct GuidedJournalExercise: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let closingLine: String?
    let fields: [GuidedJournalField]
}

enum RecoveryExerciseCatalog {
    static let guided: [GuidedJournalExercise] = [
        GuidedJournalExercise(
            id: RecoveryExerciseID.miss,
            title: "What do I actually miss?",
            subtitle: "Separate the person from the feeling, the routine, and the future you imagined.",
            closingLine: "I may not miss them. I may miss how I felt.",
            fields: [
                GuidedJournalField(id: "person", prompt: "The person"),
                GuidedJournalField(id: "feeling", prompt: "The feeling"),
                GuidedJournalField(id: "routine", prompt: "The routine"),
                GuidedJournalField(id: "companionship", prompt: "The companionship"),
                GuidedJournalField(id: "future", prompt: "The future I imagined")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.whatHappened,
            title: "What happened?",
            subtitle: "Tell the story plainly, without making anyone the villain.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "facts", prompt: "What actually happened, as fairly as I can say it"),
                GuidedJournalField(id: "my-part", prompt: "The part that was mine"),
                GuidedJournalField(id: "not-mine", prompt: "The part that was not mine")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.learned,
            title: "What did I learn?",
            subtitle: "Take one true thing with you. Leave the rest.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "about-me", prompt: "Something I learned about myself"),
                GuidedJournalField(id: "about-love", prompt: "Something I learned about love or partnership"),
                GuidedJournalField(id: "carry", prompt: "What I want to carry forward")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.notWorking,
            title: "What wasn’t working?",
            subtitle: "Name the friction without turning them into a monster.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "one", prompt: "One thing that wasn’t working"),
                GuidedJournalField(id: "two", prompt: "Another thing that wasn’t working"),
                GuidedJournalField(id: "three", prompt: "A third, if there is one")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.needs,
            title: "What needs weren’t being met?",
            subtitle: "Needs are information. They are not proof you were too much.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "mine", prompt: "A need of mine that went unmet"),
                GuidedJournalField(id: "how-it-felt", prompt: "How that felt in my body"),
                GuidedJournalField(id: "next", prompt: "How I want that need met in my life now")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.patterns,
            title: "What patterns do I want to avoid?",
            subtitle: "This is about your next relationship with yourself, not revenge.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "old", prompt: "A pattern I don’t want to repeat"),
                GuidedJournalField(id: "signal", prompt: "How I will notice it earlier next time"),
                GuidedJournalField(id: "instead", prompt: "What I want to practice instead")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.besides,
            title: "What did I lose besides the relationship?",
            subtitle: "Sometimes the ache is also a home, a plan, or a version of the week.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "lost", prompt: "What else I lost"),
                GuidedJournalField(id: "still-here", prompt: "What is still here"),
                GuidedJournalField(id: "rebuild", prompt: "One piece I can slowly rebuild")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.before,
            title: "Who was I before this relationship?",
            subtitle: "You existed before them. That person is still reachable.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "before", prompt: "Who I was before"),
                GuidedJournalField(id: "quieted", prompt: "What went quiet while I was with them"),
                GuidedJournalField(id: "return", prompt: "One piece of that person I can invite back")
            ]
        ),
        GuidedJournalExercise(
            id: RecoveryExerciseID.become,
            title: "Who do I want to become?",
            subtitle: "Not a new personality. Just a better direction.",
            closingLine: nil,
            fields: [
                GuidedJournalField(id: "become", prompt: "Who I want to become"),
                GuidedJournalField(id: "already", prompt: "A way I am already that person"),
                GuidedJournalField(id: "step", prompt: "One small step this week")
            ]
        )
    ]

    static let dailyPromptIDs: Set<String> = [
        "red-flags", "self-win",
        "good-moment", "made-me-smile", "looking-forward"
    ]

    static func guided(id: String) -> GuidedJournalExercise? {
        guided.first { $0.id == id }
    }

    static func coachExercise(fromTag tag: String) -> CoachExercise? {
        switch tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "contact-urge":
            return CoachExercise(label: "Slow down before you text", destination: .contactUrge)
        case "reality-check":
            return CoachExercise(label: "Do a Reality Check", destination: .realityCheck)
        case "miss":
            return CoachExercise(label: "What do I actually miss?", destination: .journalExercise(RecoveryExerciseID.miss))
        case "rebuild":
            return CoachExercise(label: "Take today’s rebuild step", destination: .rebuild)
        case "calm":
            return CoachExercise(label: "Come to Calm Space", destination: .calmSpace(.breathe))
        case "urge-wave":
            return CoachExercise(label: "2 quiet minutes", destination: .urgeWave)
        default:
            return nil
        }
    }

    static func inferredCoachExercise(fromUserText text: String) -> CoachExercise? {
        let haystack = RecoveryMood.normalized(text)
        if ["text them", "text her", "text him", "text my ex", "want to contact", "should i text"].contains(where: { haystack.contains($0) }) {
            return coachExercise(fromTag: "contact-urge")
        }
        if ["instagram", "checking their", "can't stop", "cant stop", "overthinking", "she was perfect", "never find"].contains(where: { haystack.contains($0) }) {
            return coachExercise(fromTag: "reality-check")
        }
        if haystack.contains("i miss") || haystack.contains("missing") {
            return coachExercise(fromTag: "miss")
        }
        if haystack.contains("lonely") || haystack.contains("tonight is hard") || haystack.contains("can't sleep") {
            return coachExercise(fromTag: "calm")
        }
        return nil
    }
}

struct CoachExercise: Equatable {
    let label: String
    let destination: RecoveryDestination
}

enum CoachExerciseParser {
    private static let pattern = #"\[\[exercise:([a-z0-9-]+)\]\]"#

    static func split(_ raw: String) -> (text: String, exercise: CoachExercise?) {
        let nsRange = NSRange(raw.startIndex..., in: raw)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: raw, options: [], range: nsRange),
              let tagRange = Range(match.range(at: 1), in: raw) else {
            return (raw.trimmingCharacters(in: .whitespacesAndNewlines), nil)
        }

        let tag = String(raw[tagRange])
        let stripped = regex.stringByReplacingMatches(in: raw, options: [], range: nsRange, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (stripped, RecoveryExerciseCatalog.coachExercise(fromTag: tag))
    }
}
