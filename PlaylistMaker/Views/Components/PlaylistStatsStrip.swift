//
//  PlaylistStatsStrip.swift
//  PlaylistMaker
//

import SwiftUI

struct PlaylistStatsStrip: View {
    let statistics: PlaylistStatistics

    var body: some View {
        HStack(spacing: 16) {
            statTile(
                icon: "music.note.list",
                title: "Songs",
                value: "\(statistics.songCount)"
            )

            Divider()
                .frame(height: 36)
                .overlay(PlaylistTheme.subtleBorder)

            statTile(
                icon: "clock.fill",
                title: "Total time",
                value: statistics.totalDurationFormatted
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(PlaylistTheme.subtleBorder, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("statsStrip")
    }

    private func statTile(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(PlaylistTheme.headerGradient)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PlaylistStatsStrip(statistics: PlaylistStatistics(songCount: 7, totalDurationSeconds: 1234))
        .padding()
        .background(Color.black.opacity(0.2))
}
