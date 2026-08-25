//
//  HealingFocus.swift
//  Mend
//
//  Light personalization from onboarding focuses — one Home tip, not a full theme engine.
//

import Foundation

enum HealingFocus: String, CaseIterable {
    case noContact = "No contact"
    case processGrief = "Process the grief"
    case hardMoments = "Hard moments"
    case rebuildRoutine = "Rebuild my routine"

    static func parse(_ raw: String) -> Set<HealingFocus> {
        let parts = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Set(parts.compactMap { HealingFocus(rawValue: $0) })
    }
}

enum HealingFocusTipDestination {
    case noContact
    case calmSpace
    case journal
    case checkIn
}

struct HealingFocusTip: Equatable {
    let title: String
    let message: String
    let actionLabel: String
    let icon: String
    let destination: HealingFocusTipDestination
}

enum HealingFocusTipBuilder {
    /// Prefer acute support first when someone picked several focuses.
    private static let priority: [HealingFocus] = [
        .hardMoments,
        .noContact,
        .processGrief,
        .rebuildRoutine
    ]

    static func tip(
        healingFocusRaw: String,
        noContactIsActive: Bool,
        noContactDays: Int
    ) -> HealingFocusTip {
        let focuses = HealingFocus.parse(healingFocusRaw)
        let chosen = priority.first(where: { focuses.contains($0) }) ?? focuses.first

        switch chosen {
        case .hardMoments:
            return HealingFocusTip(
                title: "Feeling the urge?",
                message: "If you want to text them, come into Calm Space with me. We’ll ride this wave together. Nothing has to be sent.",
                actionLabel: "Come to Calm Space",
                icon: "heart.circle.fill",
                destination: .calmSpace
            )

        case .noContact:
            if noContactIsActive {
                let dayText = noContactDays == 1 ? "1 gentle day" : "\(noContactDays) gentle days"
                return HealingFocusTip(
                    title: "No contact",
                    message: "You’re on \(dayText). Peek at your streak anytime you need a quiet reminder you’re caring for yourself.",
                    actionLabel: "See my streak",
                    icon: "leaf.fill",
                    destination: .noContact
                )
            }
            return HealingFocusTip(
                title: "No contact",
                message: "When you’re ready, we can track your days so hard moments feel a little less alone.",
                actionLabel: "See my streak",
                icon: "leaf.fill",
                destination: .noContact
            )

        case .processGrief:
            return HealingFocusTip(
                title: "Make room for the grief",
                message: "Pour it onto the page when it needs somewhere kind to go. A breakup prompt can help you begin.",
                actionLabel: "Open your journal",
                icon: "heart.text.square.fill",
                destination: .journal
            )

        case .rebuildRoutine:
            return HealingFocusTip(
                title: "One small kindness",
                message: "Rebuild gently. Write one thing you did for yourself today. Even something tiny counts.",
                actionLabel: "Open your journal",
                icon: "sun.and.horizon.fill",
                destination: .journal
            )

        case nil:
            return HealingFocusTip(
                title: "Today",
                message: "When feelings get loud, come into Calm Space with me and take one slow breath.",
                actionLabel: "Come to Calm Space",
                icon: "heart.fill",
                destination: .calmSpace
            )
        }
    }
}
