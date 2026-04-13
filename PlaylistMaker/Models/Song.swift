//
//  Song.swift
//  PlaylistMaker
//

import Foundation

nonisolated struct Song: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var title: String
    var artist: String
    var genre: String
    /// Length in seconds.
    var durationSeconds: TimeInterval
    /// Cached iTunes preview URL (30s stream) when resolved.
    var previewURL: String?

    init(
        id: UUID,
        title: String,
        artist: String,
        genre: String,
        durationSeconds: TimeInterval,
        previewURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genre = genre
        self.durationSeconds = durationSeconds
        self.previewURL = previewURL
    }

    var durationFormatted: String {
        SongDurationFormatter.string(from: durationSeconds)
    }
}

nonisolated enum SongDurationFormatter {
    static func string(from seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
