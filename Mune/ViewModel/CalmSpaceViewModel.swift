//
//  CalmSpaceViewModel.swift
//  Mune
//

import SwiftUI
import Observation
import AVFoundation

struct SavedDrawing: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var canvasWidth: Double
    var canvasHeight: Double
    var lines: [PersistableDoodleLine]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        canvasWidth: Double,
        canvasHeight: Double,
        lines: [PersistableDoodleLine]
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.lines = lines
    }

    var doodleLines: [DoodleLine] {
        lines.map { line in
            DoodleLine(
                points: line.points.map { CGPoint(x: $0.x, y: $0.y) },
                color: .sageGreen,
                lineWidth: CGFloat(line.lineWidth)
            )
        }
    }
}

@Observable
class CalmSpaceViewModel {
    var doodleLines: [DoodleLine] = []
    var savedDrawings: [SavedDrawing] = []
    var quoteIndex = 0
    var isPlayingMusic = false
    var showContactPicker = false
    private var suppressPreferenceSideEffects = false

    var saveDrawingsEnabled: Bool {
        didSet {
            guard !suppressPreferenceSideEffects else { return }
            let profileID = Self.currentProfileID()
            UserDefaults.standard.set(saveDrawingsEnabled, forKey: Self.enabledKey(for: profileID))
            UserDefaults.standard.set(saveDrawingsEnabled, forKey: Self.saveDrawingsEnabledKey)
            if saveDrawingsEnabled {
                loadSavedDrawings()
            } else {
                savedDrawings = []
                clearSavedDrawingsFolder()
            }
        }
    }

    static let saveDrawingsEnabledKey = "saveDrawingsEnabled"
    static let savedDrawingsFolderKey = "savedCalmSpaceDrawingFolder"
    private static let legacySavedDoodlesKey = "savedCalmSpaceDoodles"
    private static let didMigrateToProfilesKey = "calmSpaceDrawings.didMigrateToProfiles.v1"

    private let calmSoundName = "calm_music"
    private let calmSoundExtension = "mp3"
    private var audioPlayer: AVAudioPlayer?

    let quotes = [
        "You can take up space in your own life again. Slow still counts.",
        "There’s room today for ease, hope, and you.",
        "You’re allowed to feel better. One small step still counts.",
        "Coming back to yourself can be quiet and still good.",
        "Healing isn’t a straight line. Showing up for yourself today still matters."
    ]

    static func currentProfileID() -> String {
        let id = LocalProfileStore.activeProfileID
        return id.isEmpty ? LocalProfileStore.legacyUserID : id
    }

    static func enabledKey(for profileID: String) -> String {
        "saveDrawingsEnabled.\(profileID)"
    }

    static func folderKey(for profileID: String) -> String {
        "savedCalmSpaceDrawingFolder.\(profileID)"
    }

    static func migrateUnscopedDrawingsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: didMigrateToProfilesKey) else { return }

        let profiles = LocalProfileStore.allProfiles()
        let targetID: String = {
            if profiles.contains(where: { $0.id == LocalProfileStore.legacyUserID }) {
                return LocalProfileStore.legacyUserID
            }
            if let first = profiles.first?.id {
                return first
            }
            let active = LocalProfileStore.activeProfileID
            return active.isEmpty ? LocalProfileStore.legacyUserID : active
        }()

        let scopedFolderKey = folderKey(for: targetID)
        if UserDefaults.standard.data(forKey: scopedFolderKey) == nil,
           let globalFolder = UserDefaults.standard.data(forKey: savedDrawingsFolderKey) {
            UserDefaults.standard.set(globalFolder, forKey: scopedFolderKey)
        }

        if UserDefaults.standard.object(forKey: enabledKey(for: targetID)) == nil {
            UserDefaults.standard.set(
                UserDefaults.standard.bool(forKey: saveDrawingsEnabledKey),
                forKey: enabledKey(for: targetID)
            )
        }

        UserDefaults.standard.removeObject(forKey: savedDrawingsFolderKey)
        UserDefaults.standard.set(true, forKey: didMigrateToProfilesKey)
    }

    static func clearDrawings(for profileID: String) {
        UserDefaults.standard.removeObject(forKey: folderKey(for: profileID))
        UserDefaults.standard.removeObject(forKey: legacySavedDoodlesKey)
    }

    init() {
        Self.migrateUnscopedDrawingsIfNeeded()
        let profileID = Self.currentProfileID()
        suppressPreferenceSideEffects = true
        if let stored = UserDefaults.standard.object(forKey: Self.enabledKey(for: profileID)) as? Bool {
            saveDrawingsEnabled = stored
        } else {
            saveDrawingsEnabled = UserDefaults.standard.bool(forKey: Self.saveDrawingsEnabledKey)
        }
        suppressPreferenceSideEffects = false
        if saveDrawingsEnabled {
            loadSavedDrawings()
        }
    }

    /// Reload drawings when switching profiles. Clears the live canvas.
    func loadForActiveProfile() {
        Self.migrateUnscopedDrawingsIfNeeded()
        doodleLines = []
        quoteIndex = 0

        let profileID = Self.currentProfileID()
        let enabled: Bool
        if let stored = UserDefaults.standard.object(forKey: Self.enabledKey(for: profileID)) as? Bool {
            enabled = stored
        } else {
            enabled = UserDefaults.standard.bool(forKey: Self.saveDrawingsEnabledKey)
        }

        suppressPreferenceSideEffects = true
        saveDrawingsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey(for: profileID))
        UserDefaults.standard.set(enabled, forKey: Self.saveDrawingsEnabledKey)
        suppressPreferenceSideEffects = false

        if enabled {
            loadSavedDrawings()
        } else {
            savedDrawings = []
        }
    }

    var currentQuote: String {
        quotes[quoteIndex]
    }

    func nextQuote() {
        quoteIndex = (quoteIndex + 1) % quotes.count
    }

    func clearCanvas() {
        doodleLines.removeAll()
    }

    func addDoodlePoint(_ point: CGPoint, isNew: Bool) {
        if isNew {
            doodleLines.append(DoodleLine(points: [point], color: .sageGreen, lineWidth: 5))
        } else {
            let index = doodleLines.count - 1
            if index >= 0 {
                doodleLines[index].points.append(point)
            }
        }
    }

    var canSaveCurrentDrawing: Bool {
        saveDrawingsEnabled && doodleLines.contains { !$0.points.isEmpty }
    }

    @discardableResult
    func saveCurrentDrawing(name: String, canvasSize: CGSize) -> Bool {
        guard saveDrawingsEnabled else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, canSaveCurrentDrawing else { return false }

        let payload = encodeLines(doodleLines)
        let drawing = SavedDrawing(
            name: trimmedName,
            canvasWidth: Double(max(canvasSize.width, 1)),
            canvasHeight: Double(max(canvasSize.height, 1)),
            lines: payload
        )

        savedDrawings.insert(drawing, at: 0)
        persistSavedDrawings()
        return true
    }

    func deleteDrawing(id: UUID) {
        savedDrawings.removeAll { $0.id == id }
        persistSavedDrawings()
    }

    func renameDrawing(id: UUID, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let index = savedDrawings.firstIndex(where: { $0.id == id }) else { return }

        savedDrawings[index].name = trimmedName
        persistSavedDrawings()
    }

    func loadDrawingIntoCanvas(_ drawing: SavedDrawing) {
        doodleLines = drawing.doodleLines
    }

    func syncDrawingPreference() {
        loadForActiveProfile()
    }

    private func loadSavedDrawings() {
        migrateLegacyDrawingIfNeeded()

        let key = Self.folderKey(for: Self.currentProfileID())
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedDrawing].self, from: data) else {
            savedDrawings = []
            return
        }

        savedDrawings = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persistSavedDrawings() {
        guard saveDrawingsEnabled else { return }

        if let data = try? JSONEncoder().encode(savedDrawings) {
            UserDefaults.standard.set(data, forKey: Self.folderKey(for: Self.currentProfileID()))
        }
    }

    private func clearSavedDrawingsFolder() {
        Self.clearDrawings(for: Self.currentProfileID())
    }

    private func migrateLegacyDrawingIfNeeded() {
        let profileID = Self.currentProfileID()
        let scopedKey = Self.folderKey(for: profileID)
        guard UserDefaults.standard.data(forKey: scopedKey) == nil,
              let legacyData = UserDefaults.standard.data(forKey: Self.legacySavedDoodlesKey),
              let legacyLines = try? JSONDecoder().decode([PersistableDoodleLine].self, from: legacyData),
              !legacyLines.isEmpty else {
            return
        }

        let migrated = SavedDrawing(
            name: "Saved drawing",
            canvasWidth: 350,
            canvasHeight: 420,
            lines: legacyLines
        )
        savedDrawings = [migrated]
        persistSavedDrawings()
        UserDefaults.standard.removeObject(forKey: Self.legacySavedDoodlesKey)
    }

    private func encodeLines(_ lines: [DoodleLine]) -> [PersistableDoodleLine] {
        lines.map { line in
            PersistableDoodleLine(
                points: line.points.map { PersistablePoint(x: $0.x, y: $0.y) },
                lineWidth: Double(line.lineWidth)
            )
        }
    }

    func toggleMusic() {
        if isPlayingMusic {
            stopCalmSound()
        } else {
            startCalmSound()
        }
        isPlayingMusic.toggle()
    }

    private func startCalmSound() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            guard let url = Bundle.main.url(forResource: calmSoundName, withExtension: calmSoundExtension) else {
                isPlayingMusic = false
                return
            }

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.75
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            isPlayingMusic = false
        }
    }

    private func stopCalmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func callEmergency(_ number: String) {
        if let url = URL(string: "tel://\(number)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func textEmergency(_ number: String) {
        if let url = URL(string: "sms://\(number)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

struct PersistableDoodleLine: Codable, Equatable {
    var points: [PersistablePoint]
    var lineWidth: Double
}

struct PersistablePoint: Codable, Equatable {
    var x: Double
    var y: Double
}
