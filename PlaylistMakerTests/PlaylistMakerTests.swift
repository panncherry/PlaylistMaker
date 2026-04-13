//
//  PlaylistMakerTests.swift
//  PlaylistMakerTests
//
//  Created by Pann Cherry on 4/12/26.
//

import Testing

@testable import PlaylistMaker

struct PlaylistMakerTests {
    @Test func durationFormatting() {
        #expect(SongDurationFormatter.string(from: 65) == "1:05")
        #expect(SongDurationFormatter.string(from: 0) == "0:00")
    }
}
