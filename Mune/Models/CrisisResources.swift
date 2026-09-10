//
//  CrisisResources.swift
//  Mune
//
//  Worldwide-first crisis links. Prefer IASP over a single-country hotline.
//

import Foundation

enum CrisisResources {
    /// International Association for Suicide Prevention — find a local helpline.
    static let findHelplineURL = URL(string: "https://www.iasp.info/suicidalthoughts/")!

    /// Local emergency number based on the device region.
    static var emergencyNumber: String {
        let region = Locale.current.region?.identifier ?? ""
        return region.uppercased() == "US" ? "911" : "112"
    }

    static var emergencyTelURL: URL? {
        URL(string: "tel://\(emergencyNumber)")
    }

    static var isUSRegion: Bool {
        (Locale.current.region?.identifier ?? "").uppercased() == "US"
    }

    static let usLifelineCallURL = URL(string: "tel://988")
    static let usLifelineTextURL = URL(string: "sms:988")
}
