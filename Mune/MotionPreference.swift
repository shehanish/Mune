//
//  MotionPreference.swift
//  Mune
//

import SwiftUI

enum MotionPreference {
    static let reduceMotionKey = "reduceMotionEnabled"

    /// Honors the in-app toggle and the system Reduce Motion setting.
    static var shouldReduceMotion: Bool {
        UserDefaults.standard.bool(forKey: reduceMotionKey)
            || UIAccessibility.isReduceMotionEnabled
    }
}
