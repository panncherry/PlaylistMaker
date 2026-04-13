//
//  PlaylistPersistence.swift
//  PlaylistMaker
//

import Foundation

struct PlaylistPersistence: Sendable {
    static let storageKey = "playlistMaker.savedPlaylist.v1"

    private let defaults: UserDefaults
    private let key = Self.storageKey

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Song] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Song].self, from: data)) ?? []
    }

    func save(_ songs: [Song]) {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        defaults.set(data, forKey: key)
    }
}
