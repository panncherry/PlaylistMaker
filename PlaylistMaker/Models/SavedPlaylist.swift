//
//  SavedPlaylist.swift
//  PlaylistMaker
//

import Foundation

struct SavedPlaylist: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var songs: [Song]
    var createdAt: Date

    init(id: UUID = UUID(), name: String, songs: [Song] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.songs = songs
        self.createdAt = createdAt
    }
}

struct AppLibraryState: Codable, Sendable {
    static let currentVersion = 2

    var version: Int
    var playlists: [SavedPlaylist]
    var selectedPlaylistId: UUID

    static func emptyFirstPlaylist(named: String = "Favorites") -> AppLibraryState {
        let pl = SavedPlaylist(name: named)
        return AppLibraryState(version: currentVersion, playlists: [pl], selectedPlaylistId: pl.id)
    }
}
