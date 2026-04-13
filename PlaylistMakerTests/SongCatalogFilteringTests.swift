//
//  SongCatalogFilteringTests.swift
//  PlaylistMakerTests
//

import Foundation
import Testing

@testable import PlaylistMaker

struct SongCatalogFilteringTests {
    @Test func emptyQueryReturnsAll() {
        let songs = [
            Song(id: UUID(), title: "A", artist: "B", genre: "C", durationSeconds: 1),
        ]
        let out = SongCatalogFiltering.filter(songs, matching: "   ")
        #expect(out.count == 1)
    }

    @Test func filtersByTitle() {
        let a = Song(id: UUID(), title: "Neon Sky", artist: "X", genre: "Y", durationSeconds: 1)
        let b = Song(id: UUID(), title: "Other", artist: "X", genre: "Y", durationSeconds: 1)
        let out = SongCatalogFiltering.filter([a, b], matching: "neon")
        #expect(out.count == 1)
        #expect(out[0].title == "Neon Sky")
    }

    @Test func filtersByArtistCaseInsensitive() {
        let a = Song(id: UUID(), title: "T", artist: "Velvet Pulse", genre: "Y", durationSeconds: 1)
        let out = SongCatalogFiltering.filter([a], matching: "VELVET")
        #expect(out.count == 1)
    }
}
