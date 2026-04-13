//
//  PlaylistStore.swift
//  PlaylistMaker
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class PlaylistStore {
    private(set) var catalog: [Song]
    private var libraryState: AppLibraryState

    var playlists: [SavedPlaylist] { libraryState.playlists }

    var selectedPlaylistId: UUID {
        libraryState.selectedPlaylistId
    }

    var activePlaylist: SavedPlaylist {
        libraryState.playlists.first(where: { $0.id == libraryState.selectedPlaylistId })
            ?? libraryState.playlists[0]
    }

    /// Songs in the currently selected playlist (primary editing target from Browse).
    var playlist: [Song] {
        activePlaylist.songs
    }

    var statistics: PlaylistStatistics {
        PlaylistStatistics.compute(for: activePlaylist.songs)
    }

    /// Distinct genres from the bundled catalog (for filters).
    var catalogGenres: [String] {
        let set = Set(catalog.map(\.genre))
        return set.sorted()
    }

    init(catalog: [Song], library: AppLibraryState? = nil) {
        self.catalog = catalog
        if let library {
            self.libraryState = library
        } else {
            self.libraryState = LibraryFilePersistence.loadOrMigrate()
        }
    }

    func selectPlaylist(id: UUID) {
        guard libraryState.playlists.contains(where: { $0.id == id }) else { return }
        libraryState.selectedPlaylistId = id
        persist()
    }

    func createPlaylist(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.isEmpty ? "Playlist \(libraryState.playlists.count + 1)" : trimmed
        let pl = SavedPlaylist(name: title)
        libraryState.playlists.append(pl)
        libraryState.selectedPlaylistId = pl.id
        persist()
    }

    func renamePlaylist(id: UUID, to name: String) {
        guard let idx = libraryState.playlists.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        libraryState.playlists[idx].name = trimmed
        persist()
    }

    func deletePlaylist(id: UUID) {
        guard libraryState.playlists.count > 1 else { return }
        libraryState.playlists.removeAll { $0.id == id }
        if libraryState.selectedPlaylistId == id {
            libraryState.selectedPlaylistId = libraryState.playlists[0].id
        }
        persist()
    }

    /// Reorders playlists in the library list. Does not change which playlist is selected for Browse.
    func movePlaylists(fromOffsets: IndexSet, toOffset: Int) {
        libraryState.playlists.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persist()
    }

    func isInPlaylist(_ song: Song) -> Bool {
        activePlaylist.songs.contains(where: { $0.id == song.id })
    }

    func isInAnyPlaylist(_ song: Song) -> Bool {
        libraryState.playlists.contains { pl in
            pl.songs.contains(where: { $0.id == song.id })
        }
    }

    func otherPlaylistNamesContaining(_ song: Song) -> [String] {
        libraryState.playlists
            .filter { $0.id != selectedPlaylistId }
            .filter { pl in pl.songs.contains(where: { $0.id == song.id }) }
            .map(\.name)
    }

    func containsSong(_ song: Song, inPlaylistId playlistId: UUID) -> Bool {
        guard let pl = libraryState.playlists.first(where: { $0.id == playlistId }) else {
            return false
        }
        return pl.songs.contains(where: { $0.id == song.id })
    }

    @discardableResult
    func add(_ song: Song) -> Bool {
        add(song, toPlaylistId: selectedPlaylistId)
    }

    @discardableResult
    func add(_ song: Song, toPlaylistId playlistId: UUID) -> Bool {
        guard let idx = libraryState.playlists.firstIndex(where: { $0.id == playlistId }) else {
            return false
        }
        guard !libraryState.playlists[idx].songs.contains(where: { $0.id == song.id }) else { return false }
        libraryState.playlists[idx].songs.append(song)
        persist()
        return true
    }

    func remove(_ song: Song) {
        guard let pidx = libraryState.playlists.firstIndex(where: { $0.id == selectedPlaylistId }) else { return }
        libraryState.playlists[pidx].songs.removeAll { $0.id == song.id }
        persist()
    }

    func remove(_ song: Song, fromPlaylistId playlistId: UUID) {
        guard let pidx = libraryState.playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        libraryState.playlists[pidx].songs.removeAll { $0.id == song.id }
        persist()
    }

    func move(fromOffsets: IndexSet, toOffset: Int) {
        moveSongs(inPlaylistId: selectedPlaylistId, fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func moveSongs(inPlaylistId playlistId: UUID, fromOffsets: IndexSet, toOffset: Int) {
        guard let pidx = libraryState.playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        libraryState.playlists[pidx].songs.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persist()
    }

    private func persist() {
        LibraryFilePersistence.save(libraryState)
    }
}

extension Song {
    static let previewCatalog: [Song] = [
        Song(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
            title: "Neon Skyline",
            artist: "Velvet Pulse",
            genre: "Synthwave",
            durationSeconds: 214,
            previewURL: nil
        ),
        Song(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000002")!,
            title: "Midnight Metro",
            artist: "City Echo",
            genre: "Electronic",
            durationSeconds: 198,
            previewURL: nil
        ),
    ]
}
