import Foundation

enum CrisisSignal: Equatable, Hashable {
    case selfHarm
    case harmToOthers
}

enum CrisisSupportDetector {
    /// Detects clear crisis language. Prefers phrases to reduce false positives.
    static func detect(in text: String) -> Set<CrisisSignal> {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "[^a-z0-9'\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return [] }

        var signals = Set<CrisisSignal>()

        if selfHarmPhrases.contains(where: { normalized.contains($0) }) {
            signals.insert(.selfHarm)
        }
        if harmToOthersPhrases.contains(where: { normalized.contains($0) }) {
            signals.insert(.harmToOthers)
        }

        return signals
    }

    private static let selfHarmPhrases: [String] = [
        "kill myself",
        "killing myself",
        "end my life",
        "ending my life",
        "take my life",
        "taking my life",
        "want to die",
        "wanna die",
        "wish i was dead",
        "wish i were dead",
        "better off dead",
        "don't want to live",
        "dont want to live",
        "do not want to live",
        "can't go on",
        "cant go on",
        "suicide",
        "suicidal",
        "self harm",
        "self-harm",
        "selfharm",
        "hurt myself",
        "hurting myself",
        "cut myself",
        "cutting myself",
        "hang myself",
        "overdose",
        "no reason to live",
        "end it all",
        "ending it all"
    ]

    private static let harmToOthersPhrases: [String] = [
        "kill someone",
        "kill somebody",
        "kill him",
        "kill her",
        "kill them",
        "murder someone",
        "murder him",
        "murder her",
        "hurt someone",
        "hurt somebody",
        "hurt him",
        "hurt her",
        "hurt them",
        "want to kill",
        "gonna kill",
        "going to kill"
    ]
}
