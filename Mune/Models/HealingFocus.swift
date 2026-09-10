//
//  HealingFocus.swift
//  Mune
//
//  Light personalization from onboarding focuses — one Home tip, not a full theme engine.
//

import Foundation

enum HealingFocus: String, CaseIterable {
    case healingDays = "Healing days"
    case processGrief = "Process the grief"
    case hardMoments = "Hard moments"
    case rebuildRoutine = "Rebuild my routine"

    static func parse(_ raw: String) -> Set<HealingFocus> {
        let parts = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Set(parts.compactMap { part in
            if part == "No contact" || part == "Healing days" {
                return .healingDays
            }
            return HealingFocus(rawValue: part)
        })
    }
}

enum HealingFocusTipDestination {
    case healingDays
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
        .healingDays,
        .processGrief,
        .rebuildRoutine
    ]

    static func tip(
        healingFocusRaw: String,
        healingDaysIsActive: Bool,
        healingDaysCount: Int
    ) -> HealingFocusTip {
        let focuses = HealingFocus.parse(healingFocusRaw)
        let chosen = priority.first(where: { focuses.contains($0) }) ?? focuses.first

        switch chosen {
        case .hardMoments:
            return HealingFocusTip(
                title: "Feeling the urge?",
                message: "If you want to text them, open Ride this wave in Calm Space. Two minutes. Nothing has to be sent.",
                actionLabel: "Come to Calm Space",
                icon: "heart.circle.fill",
                destination: .calmSpace
            )

        case .healingDays:
            if healingDaysIsActive {
                let dayText = healingDaysCount == 1 ? "1 gentle day" : "\(healingDaysCount) gentle days"
                return HealingFocusTip(
                    title: "Healing days",
                    message: "You’re on \(dayText). Peek anytime you need a quiet reminder you’re caring for yourself.",
                    actionLabel: "See healing days",
                    icon: "leaf.fill",
                    destination: .healingDays
                )
            }
            return HealingFocusTip(
                title: "Healing days",
                message: "When you’re ready, we can track your gentle days so hard moments feel a little less alone.",
                actionLabel: "See healing days",
                icon: "leaf.fill",
                destination: .healingDays
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
