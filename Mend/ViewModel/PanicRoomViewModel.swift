//
//  PanicRoomViewModel.swift
//  Mend
//

import SwiftUI
import Observation
import AVFoundation

@Observable
class PanicRoomViewModel {
    var ventText = ""
    var doodleLines: [DoodleLine] = []
    var quoteIndex = 0
    var isPlayingMusic = false
    var showContactPicker = false
    var saveDrawingsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(saveDrawingsEnabled, forKey: Self.saveDrawingsEnabledKey)
            if saveDrawingsEnabled {
                if doodleLines.isEmpty {
                    doodleLines = Self.loadSavedDoodles()
                } else {
                    persistDoodlesIfNeeded()
                }
            } else {
                clearSavedDoodles()
            }
        }
    }

    private static let saveDrawingsEnabledKey = "saveDrawingsEnabled"
    private static let savedDoodlesKey = "savedCalmSpaceDoodles"

    private let calmSoundName = "Nervous System Regulation (999 Hz) 1 hour handpan music Malte Marten - Malte Marten (128k)"
    private let calmSoundExtension = "mp3"
    private var audioPlayer: AVAudioPlayer?
    
    let quotes = [
        "Take it one breath at a time.",
        "This feeling will pass.",
        "You are safe here.",
        "You are stronger than this moment.",
        "It's okay to feel this way. Be gentle with yourself."
    ]

    init() {
        saveDrawingsEnabled = UserDefaults.standard.bool(forKey: Self.saveDrawingsEnabledKey)
        if saveDrawingsEnabled {
            doodleLines = Self.loadSavedDoodles()
        }
    }
    
    var currentQuote: String {
        quotes[quoteIndex]
    }
    
    func nextQuote() {
        quoteIndex = (quoteIndex + 1) % quotes.count
    }
    
    func clearDoodles() {
        doodleLines.removeAll()
        persistDoodlesIfNeeded()
    }

    func clearVentText() {
        ventText = ""
    }
    
    func addDoodlePoint(_ point: CGPoint, isNew: Bool) {
        if isNew {
            persistDoodlesIfNeeded()
            doodleLines.append(DoodleLine(points: [point], color: .sageGreen, lineWidth: 5))
        } else {
            let index = doodleLines.count - 1
            if index >= 0 {
                doodleLines[index].points.append(point)
            }
        }
    }

    func persistDoodlesIfNeeded() {
        guard saveDrawingsEnabled else { return }

        let payload = doodleLines.map { line in
            PersistableDoodleLine(
                points: line.points.map { PersistablePoint(x: $0.x, y: $0.y) },
                lineWidth: Double(line.lineWidth)
            )
        }

        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: Self.savedDoodlesKey)
        }
    }

    func syncDrawingPreference() {
        let enabled = UserDefaults.standard.bool(forKey: Self.saveDrawingsEnabledKey)
        if saveDrawingsEnabled != enabled {
            saveDrawingsEnabled = enabled
            return
        }

        if enabled && doodleLines.isEmpty {
            doodleLines = Self.loadSavedDoodles()
        }
    }

    private func clearSavedDoodles() {
        UserDefaults.standard.removeObject(forKey: Self.savedDoodlesKey)
    }

    private static func loadSavedDoodles() -> [DoodleLine] {
        guard let data = UserDefaults.standard.data(forKey: savedDoodlesKey),
              let payload = try? JSONDecoder().decode([PersistableDoodleLine].self, from: data) else {
            return []
        }

        return payload.map { line in
            DoodleLine(
                points: line.points.map { CGPoint(x: $0.x, y: $0.y) },
                color: .sageGreen,
                lineWidth: CGFloat(line.lineWidth)
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

private struct PersistableDoodleLine: Codable {
    var points: [PersistablePoint]
    var lineWidth: Double
}

private struct PersistablePoint: Codable {
    var x: Double
    var y: Double
}