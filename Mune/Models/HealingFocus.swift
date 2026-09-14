//
//  HealingFocus.swift
//  Mune
//
//  Light personalization from onboarding focuses: one Home tip, not a full theme engine.
//

import Foundation

enum HealingFocus: String, CaseIterable {
    case healingDays = "Healing days"
    case processGrief = "Process the grief"
    case hardMoments = "Hard moments"
    case rebuildRoutine = "Rebuild my routine"

    static func parse(_ raw: String) -> Set<HealingFocus> {
        Set(parseOrdered(raw))
    }

    /// Keeps the stored order, which puts the most recently chosen focus first.
    static func parseOrdered(_ raw: String) -> [HealingFocus] {
        let parts = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var seen = Set<HealingFocus>()
        var ordered: [HealingFocus] = []

        for part in parts {
            guard let focus = match(part) else { continue }
            if seen.insert(focus).inserted {
                ordered.append(focus)
            }
        }

        return ordered
    }

    private static func match(_ title: String) -> HealingFocus? {
        switch title {
        case "No contact", "Healing days":
            return .healingDays
        case "Process the grief", "Write it out":
            return .processGrief
        case "Hard moments", "Find my calm":
            return .hardMoments
        default:
            return HealingFocus(rawValue: title)
        }
    }
}

enum HealingFocusTipDestination {
    case healingDays
    case calmSpace
    case journal
    case rebuild
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
    static func tip(
        healingFocusRaw: String,
        healingDaysIsActive: Bool,
        healingDaysCount: Int
    ) -> HealingFocusTip {
        // Follow the most recent choice, so editing the focus visibly changes the tip.
        let chosen = HealingFocus.parseOrdered(healingFocusRaw).first

        switch chosen {
        case .hardMoments:
            return HealingFocusTip(
                title: "Need a break?",
                message: "If feelings get loud, open Calm Space. We can take a few breaths together.",
                actionLabel: "Open Calm Space",
                icon: "heart.circle.fill",
                destination: .calmSpace
            )

        case .healingDays:
            if healingDaysIsActive {
                let dayText = healingDaysCount == 1 ? "1 day" : "\(healingDaysCount) days"
                return HealingFocusTip(
                    title: "Healing days",
                    message: "You’re on \(dayText) without contact. That count is yours.",
                    actionLabel: "See day count",
                    icon: "leaf.fill",
                    destination: .healingDays
                )
            }
            return HealingFocusTip(
                title: "Healing days",
                message: "Want to count days since last contact? You can start anytime.",
                actionLabel: "See day count",
                icon: "leaf.fill",
                destination: .healingDays
            )

        case .processGrief:
            return HealingFocusTip(
                title: "Write something down",
                message: "One thing you did for yourself, or one thing you want this week. That’s enough.",
                actionLabel: "Open your journal",
                icon: "heart.text.square.fill",
                destination: .journal
            )

        case .rebuildRoutine:
            return HealingFocusTip(
                title: "Show up for yourself",
                message: "Pick one small step for your body, mind, or people today.",
                actionLabel: "Open Rebuild",
                icon: "sun.and.horizon.fill",
                destination: .rebuild
            )

        case nil:
            return HealingFocusTip(
                title: "Today",
                message: "Start small today. I’m here if you need a pause.",
                actionLabel: "Open Calm Space",
                icon: "heart.fill",
                destination: .calmSpace
            )
        }
    }
}
