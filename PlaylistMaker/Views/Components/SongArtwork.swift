//
//  SongArtwork.swift
//  PlaylistMaker
//

import SwiftUI

struct SongArtwork: View {
    let genre: String
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(gradient)
            Image(systemName: "music.quarternote.3")
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(radius: 2)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var gradient: LinearGradient {
        let hash = abs(genre.hashValue)
        let hue = Double(hash % 360) / 360.0
        let a = Color(hue: hue, saturation: 0.55, brightness: 0.85)
        let b = Color(hue: (hue + 0.08).truncatingRemainder(dividingBy: 1.0), saturation: 0.6, brightness: 0.55)
        return LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
