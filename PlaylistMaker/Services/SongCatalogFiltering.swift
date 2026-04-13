//
//  SongCatalogFiltering.swift
//  PlaylistMaker
//

import Foundation

enum SongCatalogFiltering {
    /// Case-insensitive match on title, artist, or genre. Empty query returns all songs.
    static func filter(_ songs: [Song], matching query: String) -> [Song] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return songs }
        let lowered = q.lowercased()
        return songs.filter { song in
            song.title.lowercased().contains(lowered)
                || song.artist.lowercased().contains(lowered)
                || song.genre.lowercased().contains(lowered)
        }
    }
}
