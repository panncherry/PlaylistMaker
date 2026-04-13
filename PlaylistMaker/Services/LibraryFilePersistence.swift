//
//  LibraryFilePersistence.swift
//  PlaylistMaker
//

import Foundation

enum LibraryFilePersistence {
    private static let fileName = "library.json"
    private static let folderName = "PlaylistMaker"

    static var libraryFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName)
    }

    /// Loads library or migrates legacy UserDefaults playlist, then saves v2 format.
    static func loadOrMigrate() -> AppLibraryState {
        let url = libraryFileURL
        if FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url),
           var state = try? JSONDecoder().decode(AppLibraryState.self, from: data) {
            if state.playlists.isEmpty {
                return .emptyFirstPlaylist()
            }
            if !state.playlists.contains(where: { $0.id == state.selectedPlaylistId }) {
                state.selectedPlaylistId = state.playlists[0].id
                save(state)
            }
            return state
        }

        if let legacy = migrateLegacyUserDefaultsPlaylist() {
            save(legacy)
            return legacy
        }

        let fresh = AppLibraryState.emptyFirstPlaylist()
        save(fresh)
        return fresh
    }

    static func save(_ state: AppLibraryState) {
        var toSave = state
        toSave.version = AppLibraryState.currentVersion
        guard let data = try? JSONEncoder().encode(toSave) else { return }
        try? data.write(to: libraryFileURL, options: .atomic)
    }

    static func resetEverything() {
        try? FileManager.default.removeItem(at: libraryFileURL)
        UserDefaults.standard.removeObject(forKey: PlaylistPersistence.storageKey)
    }

    private static func migrateLegacyUserDefaultsPlaylist() -> AppLibraryState? {
        guard let data = UserDefaults.standard.data(forKey: PlaylistPersistence.storageKey),
              let songs = try? JSONDecoder().decode([Song].self, from: data),
              !songs.isEmpty
        else { return nil }
        var state = AppLibraryState.emptyFirstPlaylist(named: "Favorites")
        state.playlists[0].songs = songs
        UserDefaults.standard.removeObject(forKey: PlaylistPersistence.storageKey)
        return state
    }
}
