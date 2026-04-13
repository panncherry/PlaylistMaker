//
//  PlaylistsRootView.swift
//  PlaylistMaker
//

import SwiftUI

struct PlaylistsRootView: View {
    @Environment(PlaylistStore.self) private var store
    @State private var newName = ""
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.playlists) { pl in
                        NavigationLink(value: pl.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pl.name)
                                    .font(.headline)
                                Text("\(pl.songs.count) songs · \(formatDuration(pl))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onDelete { idx in
                        for i in idx.sorted(by: >) {
                            let id = store.playlists[i].id
                            store.deletePlaylist(id: id)
                        }
                    }
                    .onMove { source, destination in
                        store.movePlaylists(fromOffsets: source, toOffset: destination)
                    }
                } header: {
                    Text("Your playlists")
                } footer: {
                    Text("Tap Edit to reorder playlists. Swipe left to delete a playlist.")
                        .font(.caption)
                }
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { id in
                PlaylistDetailView(playlistId: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .accessibilityIdentifier("playlistsEditButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newName = ""
                        showingNew = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("newPlaylistButton")
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newName)
                            .textInputAutocapitalization(.words)
                    }
                    .navigationTitle("New playlist")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingNew = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                store.createPlaylist(named: newName)
                                showingNew = false
                            }
                            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .accessibilityIdentifier("playlistRoot")
    }

    private func formatDuration(_ pl: SavedPlaylist) -> String {
        let total = pl.songs.reduce(0.0) { $0 + $1.durationSeconds }
        return SongDurationFormatter.string(from: total)
    }
}
