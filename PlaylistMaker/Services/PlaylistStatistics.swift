//
//  PlaylistStatistics.swift
//  PlaylistMaker
//

import Foundation

struct PlaylistStatistics: Equatable, Sendable {
    var songCount: Int
    var totalDurationSeconds: TimeInterval

    var totalDurationFormatted: String {
        SongDurationFormatter.string(from: totalDurationSeconds)
    }

    static func compute(for songs: [Song]) -> PlaylistStatistics {
        let total = songs.reduce(0.0) { $0 + $1.durationSeconds }
        return PlaylistStatistics(songCount: songs.count, totalDurationSeconds: total)
    }
}
