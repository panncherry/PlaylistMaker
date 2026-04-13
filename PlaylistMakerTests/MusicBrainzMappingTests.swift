//
//  MusicBrainzMappingTests.swift
//  PlaylistMakerTests
//

import Foundation
import Testing

@testable import PlaylistMaker

struct MusicBrainzMappingTests {
    /// Ensures bundled catalog JSON decodes and matches app model.
    @Test func catalogJSONSample() throws {
        let json = """
        [
          {
            "id": "C2000000-0000-4000-8000-000000000001",
            "title": "Test Track",
            "artist": "Test Artist",
            "genre": "Jazz",
            "durationSeconds": 200
          }
        ]
        """.data(using: .utf8)!

        let songs = try JSONDecoder().decode([Song].self, from: json)
        #expect(songs.count == 1)
        #expect(songs[0].title == "Test Track")
        #expect(songs[0].durationFormatted == "3:20")
    }
}
