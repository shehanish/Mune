//
//  RecoveryNavigator.swift
//  Mune
//
//  Shared sheets and tab jumps for the one-action recovery loop.
//

import SwiftUI

@Observable
final class RecoveryNavigator {
    var showContactUrge = false
    var showUrgeWave = false
    var showRealityCheck = false
    var realityCheckThought = ""
    var showJournalExercise = false
    var journalExerciseID: String?
    var showRebuild = false
    var showProgress = false
    var requestedTab: Int?
    var calmFocus: CalmSpaceFocus?

    func openContactUrge() {
        showContactUrge = true
    }

    func openUrgeWave() {
        showUrgeWave = true
    }

    func openRealityCheck(thought: String = "") {
        realityCheckThought = thought
        showRealityCheck = true
    }

    func openJournalExercise(_ id: String) {
        journalExerciseID = id
        showJournalExercise = true
    }

    func openRebuild() {
        showRebuild = true
    }

    func openProgress() {
        showProgress = true
    }

    func openChat() {
        requestedTab = 1
    }

    func openJournal() {
        requestedTab = 2
    }

    func openCalmSpace(focus: CalmSpaceFocus? = nil) {
        calmFocus = focus
        requestedTab = 3
    }

    func handle(_ destination: RecoveryDestination) {
        switch destination {
        case .urgeWave:
            openUrgeWave()
        case .contactUrge:
            openContactUrge()
        case .realityCheck:
            openRealityCheck()
        case .calmSpace(let focus):
            openCalmSpace(focus: focus)
        case .chat:
            openChat()
        case .journal:
            openJournal()
        case .journalExercise(let id):
            openJournalExercise(id)
        case .rebuild:
            openRebuild()
        case .progress:
            openProgress()
        case .checkIn:
            break
        }
    }
}

enum CalmSpaceFocus: String, Equatable {
    case breathe
    case ground
    case draw
}

private struct RecoveryNavigatorKey: EnvironmentKey {
    static let defaultValue = RecoveryNavigator()
}

extension EnvironmentValues {
    var recoveryNavigator: RecoveryNavigator {
        get { self[RecoveryNavigatorKey.self] }
        set { self[RecoveryNavigatorKey.self] = newValue }
    }
}
