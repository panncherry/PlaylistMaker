//
//  AddToPlaylistSheet.swift
//  PlaylistMaker
//

import SwiftUI

struct AddToPlaylistSheet: View {
    let song: Song
    @Environment(PlaylistStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var newPlaylistName = ""
    @State private var showNewPlaylistFields = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.playlists) { pl in
                        Button {
                            toggleMembership(song, playlistId: pl.id)
                        } label: {
                            HStack {
                                Text(pl.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if store.containsSong(song, inPlaylistId: pl.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .symbolRenderingMode(.monochrome)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("addToPlaylist.option.\(pl.id.uuidString)")
                    }
                } header: {
                    Text("Your playlists")
                } footer: {
                    Text("Tap a row to add or remove. The Browse toolbar still picks the default list for filters and stats.")
                        .font(.caption)
                }

                Section {
                    if showNewPlaylistFields {
                        TextField("Playlist name", text: $newPlaylistName)
                            .textInputAutocapitalization(.words)
                        Button("Create and add") {
                            createPlaylistAndAdd()
                        }
                        .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        Button {
                            showNewPlaylistFields = true
                            newPlaylistName = ""
                        } label: {
                            Label("Create new playlist", systemImage: "plus.rectangle.on.folder.fill")
                        }
                    }
                } header: {
                    Text("New")
                }
            }
            .navigationTitle("Add to playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("addToPlaylistSheet")
    }

    private func toggleMembership(_ song: Song, playlistId: UUID) {
        if store.containsSong(song, inPlaylistId: playlistId) {
            store.remove(song, fromPlaylistId: playlistId)
        } else {
            _ = store.add(song, toPlaylistId: playlistId)
        }
    }

    private func createPlaylistAndAdd() {
        let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.createPlaylist(named: trimmed)
        _ = store.add(song)
        showNewPlaylistFields = false
        newPlaylistName = ""
    }
}
