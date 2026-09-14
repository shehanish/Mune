//
//  CrisisResources.swift
//  Mune
//
//  Worldwide-first crisis links. Prefer IASP over a single-country hotline.
//

import Foundation

enum CrisisResources {
    /// International Association for Suicide Prevention: find a local helpline.
    static let findHelplineURL = URL(string: "https://www.iasp.info/suicidalthoughts/")!

    /// Local emergency number based on the device region.
    /// Falls back to IASP guidance rather than assuming EU `112` for the whole world.
    static var emergencyNumber: String {
        let region = (Locale.current.region?.identifier ?? "").uppercased()
        switch region {
        case "US", "CA", "TT", "JM", "BS", "BB", "AG", "GD", "KN", "LC", "VC", "DM":
            return "911"
        case "GB", "UK":
            return "999"
        case "AU", "NZ", "PG":
            return "000"
        case "IN":
            return "112"
        case "JP":
            return "119"
        case "KR":
            return "119"
        case "CN", "HK", "MO":
            return "110"
        case "BR":
            return "190"
        case "MX":
            return "911"
        case "ZA":
            return "10111"
        case "AE", "SA", "QA", "KW", "BH", "OM":
            return "999"
        // Most of Europe, and many other places that use the EU emergency number.
        case "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR",
             "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK",
             "SI", "ES", "SE", "IS", "NO", "CH", "LI", "MC", "AD", "SM", "VA", "TR",
             "IL", "EG", "PH", "SG", "MY", "ID", "TH", "VN", "TW":
            return "112"
        default:
            // Prefer IASP when we don't know the local number well.
            return ""
        }
    }

    /// True when we are fairly confident about the local emergency number for this region.
    static var hasKnownEmergencyNumber: Bool {
        let region = (Locale.current.region?.identifier ?? "").uppercased()
        let known: Set<String> = [
            "US", "CA", "GB", "UK", "AU", "NZ", "IN", "JP", "KR", "CN", "HK", "MO",
            "BR", "MX", "ZA", "AE", "SA", "QA", "KW", "BH", "OM",
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR",
            "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK",
            "SI", "ES", "SE", "IS", "NO", "CH", "PH", "SG", "MY", "ID", "TH", "VN", "TW", "IL", "EG", "TR"
        ]
        return known.contains(region)
    }

    static var emergencyTelURL: URL? {
        guard hasKnownEmergencyNumber else { return nil }
        return URL(string: "tel://\(emergencyNumber)")
    }

    static var isUSRegion: Bool {
        (Locale.current.region?.identifier ?? "").uppercased() == "US"
    }

    static let usLifelineCallURL = URL(string: "tel://988")
    static let usLifelineTextURL = URL(string: "sms:988")

    static var privacyPolicyURL: URL {
        URL(string: "https://shehanish.github.io/Mune/privacy-policy.html")!
    }

    static var termsOfUseURL: URL {
        URL(string: "https://shehanish.github.io/Mune/terms-of-use.html")!
    }
}
