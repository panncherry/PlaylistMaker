//
//  PlaylistDetailView.swift
//  PlaylistMaker
//

import SwiftUI

struct PlaylistDetailView: View {
    @Environment(PlaylistStore.self) private var store
    @Environment(PlaybackManager.self) private var playback
    @Environment(NetworkReachability.self) private var network
    let playlistId: UUID

    @State private var pendingUndo: Song?
    @State private var undoWorkItem: DispatchWorkItem?

    private var playlist: SavedPlaylist? {
        store.playlists.first(where: { $0.id == playlistId })
    }

    var body: some View {
        Group {
            if let playlist {
                listContent(playlist)
            } else {
                ContentUnavailableView("Missing playlist", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let pl = playlist, !pl.songs.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .accessibilityIdentifier("playlistEditButton")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if pendingUndo != nil {
                HStack {
                    Text("Removed from playlist")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Button("Undo") {
                        undoRemove()
                    }
                    .font(.subheadline.weight(.bold))
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding()
                .accessibilityIdentifier("undoRemoveBanner")
            }
        }
    }

    @ViewBuilder
    private func listContent(_ playlist: SavedPlaylist) -> some View {
        if playlist.songs.isEmpty {
            emptyState(name: playlist.name)
        } else {
            List {
                Section {
                    PlaylistStatsStrip(statistics: PlaylistStatistics.compute(for: playlist.songs))
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(playlist.songs) { song in
                        playlistRow(song)
                    }
                    .onDelete { indexSet in
                        let snap = playlist.songs
                        for i in indexSet.sorted(by: >) {
                            store.remove(snap[i], fromPlaylistId: playlist.id)
                        }
                    }
                    .onMove { source, dest in
                        store.moveSongs(inPlaylistId: playlist.id, fromOffsets: source, toOffset: dest)
                    }
                } header: {
                    songsSectionHeader(playlist)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    @ViewBuilder
    private func songsSectionHeader(_ playlist: SavedPlaylist) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Label("Songs", systemImage: "music.note")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .labelStyle(.titleAndIcon)
                .symbolRenderingMode(.hierarchical)

            Spacer(minLength: 8)

            HStack(spacing: 14) {
                Button {
                    if playback.isQueuePlaybackActive {
                        playback.toggleQueuePlayPause()
                    } else {
                        Task { await playback.playAllPreviews(songs: playlist.songs) }
                    }
                } label: {
                    Image(systemName: playAllHeaderSymbol())
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(PlaylistTheme.accent)
                .disabled(playAllHeaderDisabled(playlist))
                .accessibilityLabel(playAllAccessibilityLabel())
                .accessibilityIdentifier("playlistPlayAll")

                Button {
                    Task { await playback.shuffleAndPlayPreviews(songs: playlist.songs) }
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(PlaylistTheme.accent)
                .disabled(!canStartPlaylistPreviews(playlist.songs))
                .accessibilityLabel("Shuffle")
                .accessibilityIdentifier("playlistShuffle")

                Menu {
                    let text = PlaylistExportService.plainText(playlistName: playlist.name, songs: playlist.songs)
                    ShareLink(item: text, preview: SharePreview(playlist.name)) {
                        Label("Share as text", systemImage: "doc.text")
                    }
                    let csv = PlaylistExportService.csv(songs: playlist.songs)
                    ShareLink(item: csv, preview: SharePreview("\(playlist.name).csv")) {
                        Label("Share as CSV", systemImage: "tablecells")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                }
                .foregroundStyle(PlaylistTheme.accent)
                .accessibilityIdentifier("playlistShareMenu")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }

    private func playAllHeaderSymbol() -> String {
        if playback.isQueuePlaybackActive {
            return playback.isPlaying ? "pause.circle.fill" : "play.circle.fill"
        }
        return "play.circle.fill"
    }

    private func playAllAccessibilityLabel() -> String {
        if playback.isQueuePlaybackActive {
            return playback.isPlaying ? "Pause" : "Resume"
        }
        return "Play all"
    }

    private func playAllHeaderDisabled(_ playlist: SavedPlaylist) -> Bool {
        if playback.isQueuePlaybackActive {
            return playback.isPreparing
        }
        return !canStartPlaylistPreviews(playlist.songs)
    }

    private func emptyState(name: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(PlaylistTheme.headerGradient)
            Text("“\(name)” is empty")
                .font(.title3.weight(.bold))
            Text("Add songs from Browse — tap Add on a song to choose a playlist or create a new one.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func playlistRow(_ song: Song) -> some View {
        HStack(alignment: .center, spacing: 14) {
            SongArtwork(genre: song.genre, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(song.genre)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                    Text(song.durationFormatted)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 0)

            Button {
                Task { await playback.togglePreview(for: song) }
            } label: {
                Image(systemName: playback.nowPlaying?.id == song.id && playback.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(PlaylistTheme.accent)
            }
            .buttonStyle(.borderless)
            .disabled(!network.isConnected && song.previewURL == nil)
            .accessibilityLabel("Play preview")
            .accessibilityIdentifier("playlist.preview.\(song.id.uuidString)")

            Button {
                removeWithUndo(song)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, Color.red.opacity(0.2))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove from playlist")
            .accessibilityIdentifier("playlist.remove.\(song.id.uuidString)")
        }
        .padding(.vertical, 6)
        .contextMenu {
            Button("Play preview", systemImage: "play.circle") {
                Task { await playback.togglePreview(for: song) }
            }
            .disabled(!network.isConnected && song.previewURL == nil)

            Button("Open in Apple Music", systemImage: "music.note") {
                MusicLinkOpener.openAppleMusicSearch(title: song.title, artist: song.artist)
            }
            Button("Open in Spotify", systemImage: "dot.radiowaves.left.and.right") {
                MusicLinkOpener.openSpotifySearch(title: song.title, artist: song.artist)
            }
        }
    }

    private func removeWithUndo(_ song: Song) {
        store.remove(song, fromPlaylistId: playlistId)
        pendingUndo = song
        undoWorkItem?.cancel()
        let work = DispatchWorkItem {
            pendingUndo = nil
        }
        undoWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func undoRemove() {
        guard let song = pendingUndo else { return }
        undoWorkItem?.cancel()
        pendingUndo = nil
        _ = store.add(song, toPlaylistId: playlistId)
    }

    /// Allows preview playback when online, or offline if at least one song has a cached preview URL.
    private func canStartPlaylistPreviews(_ songs: [Song]) -> Bool {
        network.isConnected || songs.contains { $0.previewURL != nil }
    }
}
