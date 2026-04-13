//
//  PlaylistStatisticsTests.swift
//  PlaylistMakerTests
//

import Foundation
import Testing

@testable import PlaylistMaker

struct PlaylistStatisticsTests {
    @Test func emptyPlaylist() {
        let stats = PlaylistStatistics.compute(for: [])
        #expect(stats.songCount == 0)
        #expect(stats.totalDurationSeconds == 0)
    }

    @Test func sumsDurations() {
        let songs = [
            Song(
                id: UUID(uuidString: "00000000-0000-4000-8000-0000000000B1")!,
                title: "T",
                artist: "A",
                genre: "G",
                durationSeconds: 90
            ),
            Song(
                id: UUID(uuidString: "00000000-0000-4000-8000-0000000000B2")!,
                title: "T2",
                artist: "A",
                genre: "G",
                durationSeconds: 30
            ),
        ]
        let stats = PlaylistStatistics.compute(for: songs)
        #expect(stats.songCount == 2)
        #expect(stats.totalDurationSeconds == 120)
    }
}
