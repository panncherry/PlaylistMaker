//
//  PlaylistStoreTests.swift
//  PlaylistMakerTests
//

import Foundation
import Testing

@testable import PlaylistMaker

@MainActor
struct PlaylistStoreTests {
    private let songA = Song(
        id: UUID(uuidString: "00000000-0000-4000-8000-0000000000A1")!,
        title: "A",
        artist: "Artist A",
        genre: "Pop",
        durationSeconds: 120,
        previewURL: nil
    )

    private let songB = Song(
        id: UUID(uuidString: "00000000-0000-4000-8000-0000000000A2")!,
        title: "B",
        artist: "Artist B",
        genre: "Rock",
        durationSeconds: 180,
        previewURL: nil
    )

    private func emptyTestLibrary() -> AppLibraryState {
        let pid = UUID(uuidString: "00000000-0000-4000-8000-00000000ABCD")!
        return AppLibraryState(
            version: 2,
            playlists: [
                SavedPlaylist(id: pid, name: "Test", songs: [], createdAt: .now),
            ],
            selectedPlaylistId: pid
        )
    }

    private func twoPlaylistLibrary() -> AppLibraryState {
        let a = UUID(uuidString: "00000000-0000-4000-8000-00000000AAA1")!
        let b = UUID(uuidString: "00000000-0000-4000-8000-00000000AAA2")!
        return AppLibraryState(
            version: 2,
            playlists: [
                SavedPlaylist(id: a, name: "One", songs: [], createdAt: .now),
                SavedPlaylist(id: b, name: "Two", songs: [], createdAt: .now),
            ],
            selectedPlaylistId: a
        )
    }

    @Test func addPreventsDuplicates() {
        let store = PlaylistStore(catalog: [songA, songB], library: emptyTestLibrary())

        #expect(store.add(songA) == true)
        #expect(store.add(songA) == false)
        #expect(store.playlist.count == 1)
    }

    @Test func removeAllowsReAdd() {
        let store = PlaylistStore(catalog: [songA], library: emptyTestLibrary())

        #expect(store.add(songA) == true)
        #expect(store.isInPlaylist(songA))

        store.remove(songA)
        #expect(!store.isInPlaylist(songA))
        #expect(store.add(songA) == true)
    }

    @Test func movePlaylistsReordersAndPreservesSelection() {
        let lib = twoPlaylistLibrary()
        let store = PlaylistStore(catalog: [songA], library: lib)
        let firstId = lib.playlists[0].id
        let secondId = lib.playlists[1].id
        #expect(store.playlists.map(\.name) == ["One", "Two"])
        #expect(store.selectedPlaylistId == firstId)

        store.movePlaylists(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        #expect(store.playlists.map(\.name) == ["Two", "One"])
        #expect(store.selectedPlaylistId == firstId)
        #expect(store.playlists[1].id == firstId)
        #expect(store.playlists[0].id == secondId)
    }

    @Test func containsSongReflectsPlaylistMembership() {
        let lib = twoPlaylistLibrary()
        let store = PlaylistStore(catalog: [songA], library: lib)
        let oneId = lib.playlists[0].id
        let twoId = lib.playlists[1].id

        #expect(!store.containsSong(songA, inPlaylistId: oneId))
        #expect(store.add(songA, toPlaylistId: twoId) == true)
        #expect(!store.containsSong(songA, inPlaylistId: oneId))
        #expect(store.containsSong(songA, inPlaylistId: twoId))
    }

    @Test func statisticsTrackCountAndDuration() {
        let store = PlaylistStore(catalog: [songA, songB], library: emptyTestLibrary())

        _ = store.add(songA)
        _ = store.add(songB)

        let stats = store.statistics
        #expect(stats.songCount == 2)
        #expect(stats.totalDurationSeconds == 300)
        #expect(stats.totalDurationFormatted == "5:00")
    }
}
