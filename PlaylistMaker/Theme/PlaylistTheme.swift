//
//  PlaylistTheme.swift
//  PlaylistMaker
//

import SwiftUI

enum PlaylistTheme {
    static let accent = Color(red: 0.45, green: 0.35, blue: 0.98)
    static let accentSecondary = Color(red: 0.95, green: 0.35, blue: 0.55)

    static let headerGradient = LinearGradient(
        colors: [
            Color(red: 0.32, green: 0.18, blue: 0.72),
            Color(red: 0.55, green: 0.22, blue: 0.45),
            Color(red: 0.18, green: 0.45, blue: 0.82),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let subtleBorder = Color.white.opacity(0.12)
}
