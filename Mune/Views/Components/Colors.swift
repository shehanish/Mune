//
//  Colors.swift
//  Mune
//
//  Created by Shehani Hansika on 07.05.26.
//
import SwiftUI

extension Color {
    // MARK: - Healing Purple Palette
    static let darkCharcoal = Color(red: 76/255, green: 43/255, blue: 111/255) // Deep violet plum
    static let mutedForest  = Color(red: 52/255, green: 31/255, blue: 78/255) // Rich eggplant
    static let sageGreen    = Color(red: 176/255, green: 146/255, blue: 214/255) // Lavender mauve
    static let softSand     = Color(red: 252/255, green: 248/255, blue: 255/255) // Soft lilac white
    static let warmGray     = Color(red: 238/255, green: 228/255, blue: 248/255) // Pale orchid gray

    // MARK: - Brand Colors
    static let brandPrimary = darkCharcoal
    static let brandFill = darkCharcoal
    static let textOnPrimary = mutedForest
    static let textSecondary = Color.black.opacity(0.45)
    static let buttonText = softSand

    // MARK: - Surfaces (cards, fields, chips)
    static let cardSurface = Color.white.opacity(0.88)
    static let cardSurfaceStrong = Color.white.opacity(0.96)
    static let cardSurfaceSoft = Color.white.opacity(0.75)
    static let cardSurfaceMuted = Color.white.opacity(0.50)
    static let fieldSurface = Color.white.opacity(0.85)
    static let chipSurface = Color.white.opacity(0.90)

    // MARK: - App Background Gradient
    static let bgTop = Color(red: 251/255, green: 245/255, blue: 255/255)
    static let bgMiddle = Color(red: 244/255, green: 236/255, blue: 255/255)
    static let bgBottom = Color(red: 233/255, green: 220/255, blue: 248/255)

    static let appBackgroundGradient = LinearGradient(
        colors: [bgTop, bgMiddle, bgBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.96),
            darkCharcoal.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
