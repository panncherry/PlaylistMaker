//
//  BrowseView.swift
//  PlaylistMaker
//

import SwiftUI

struct BrowseView: View {
    @Environment(PlaylistStore.self) private var store
    @Environment(PlaybackManager.self) private var playback
    @Environment(NetworkReachability.self) private var network
    @Environment(RecentSearchStore.self) private var recent

    @State private var query = ""
    @State private var selectedGenreFilter: String?
    @State private var hideSongsInPlaylist = false

    @State private var remoteResults: [Song] = []
    @State private var remoteHasMore = false
    @State private var nextRemoteOffset = 0
    @State private var lastRemoteQuery = ""
    @State private var isSearchingRemote = false
    @State private var isLoadingMoreRemote = false
    @State private var searchError: String?

    @State private var debouncedRemoteTask: Task<Void, Never>?
    @State private var isDebouncingRemote = false
    @State private var songForPlaylistPicker: Song?

    private let musicClient = MusicBrainzClient()
    private let remotePageSize = 20
    private let remoteDebounceNanoseconds: UInt64 = 350_000_000

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedFeatured: [Song] {
        var list = SongCatalogFiltering.filter(store.catalog, matching: query)
        if let g = selectedGenreFilter {
            list = list.filter { $0.genre == g }
        }
        if hideSongsInPlaylist {
            list = list.filter { !store.isInPlaylist($0) }
        }
        return list
    }

    private var showOnlineSection: Bool {
        !trimmedQuery.isEmpty
    }

    private var shouldShowOnlineEmptyPlaceholder: Bool {
        !isDebouncingRemote
            && !isSearchingRemote
            && !isLoadingMoreRemote
            && remoteResults.isEmpty
            && searchError == nil
            && !trimmedQuery.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if !network.isConnected {
                    Section {
                        Label(
                            "You’re offline. Featured library works; MusicBrainz and previews need a connection.",
                            systemImage: "wifi.slash"
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                        .listRowBackground(Color.orange.opacity(0.12))
                    }
                }

                Section {
                    PlaylistStatsStrip(statistics: store.statistics)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    if displayedFeatured.isEmpty {
                        ContentUnavailableView(
                            "No matches",
                            systemImage: "magnifyingglass",
                            description: Text(emptyFeaturedDescription)
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(displayedFeatured) { song in
                            songRow(song)
                        }
                    }
                } header: {
                    sectionHeader(title: "Featured library", systemImage: "sparkles")
                }

                if showOnlineSection {
                    Section {
                        if isSearchingRemote && remoteResults.isEmpty && searchError == nil {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .accessibilityIdentifier("searchProgress")
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        }

                        ForEach(remoteResults) { song in
                            songRow(song)
                        }

                        if remoteHasMore {
                            Button {
                                Task { await fetchRemoteNextPage() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoadingMoreRemote {
                                        ProgressView()
                                            .accessibilityIdentifier("loadMoreProgress")
                                    } else {
                                        Label("Load more", systemImage: "arrow.down.circle")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .disabled(isLoadingMoreRemote || isSearchingRemote || !network.isConnected)
                            .accessibilityIdentifier("remoteLoadMore")
                        }

                        if shouldShowOnlineEmptyPlaceholder {
                            ContentUnavailableView(
                                "No online matches",
                                systemImage: "globe",
                                description: Text("Try another keyword or use Load more when available.")
                            )
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        sectionHeader(title: "Online (MusicBrainz)", systemImage: "globe")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $query,
                prompt: "Search library & MusicBrainz"
            ) {
                if !recent.queries.isEmpty {
                    Section {
                        ForEach(recent.queries, id: \.self) { q in
                            Button(q) {
                                query = q
                            }
                        }
                    } header: {
                        Text("Recent searches")
                    }
                }
            }
            .onSubmit(of: .search) {
                debouncedRemoteTask?.cancel()
                debouncedRemoteTask = nil
                isDebouncingRemote = false
                Task { await fetchRemoteFirstPage() }
            }
            .onChange(of: query) { _, _ in
                if trimmedQuery.isEmpty {
                    isDebouncingRemote = false
                    debouncedRemoteTask?.cancel()
                    debouncedRemoteTask = nil
                    remoteResults = []
                    remoteHasMore = false
                    nextRemoteOffset = 0
                    lastRemoteQuery = ""
                    isSearchingRemote = false
                    isLoadingMoreRemote = false
                    searchError = nil
                } else {
                    isDebouncingRemote = true
                    scheduleDebouncedRemoteSearch()
                }
            }
            .onDisappear {
                debouncedRemoteTask?.cancel()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Target playlist", selection: Binding(
                            get: { store.selectedPlaylistId },
                            set: { store.selectPlaylist(id: $0) }
                        )) {
                            ForEach(store.playlists) { pl in
                                Text(pl.name).tag(pl.id)
                            }
                        }
                    } label: {
                        Label("Playlist", systemImage: "music.note.list")
                    }
                    .accessibilityIdentifier("browseTargetPlaylistMenu")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Genre", selection: $selectedGenreFilter) {
                            Text("All genres").tag(String?.none)
                            ForEach(store.catalogGenres, id: \.self) { g in
                                Text(g).tag(Optional(g))
                            }
                        }
                        Toggle("Hide songs in playlist", isOn: $hideSongsInPlaylist)
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityIdentifier("browseFiltersMenu")
                }
            }
            .overlay(alignment: .top) {
                if let searchError {
                    Text(searchError)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.red.gradient, in: Capsule())
                        .padding(.top, 6)
                        .accessibilityIdentifier("searchErrorBanner")
                }
            }
            .sheet(item: $songForPlaylistPicker) { song in
                AddToPlaylistSheet(song: song)
            }
        }
        .accessibilityIdentifier("browseRoot")
    }

    private var emptyFeaturedDescription: String {
        if trimmedQuery.isEmpty, selectedGenreFilter == nil, !hideSongsInPlaylist {
            return "No songs in the featured library."
        }
        return "Try clearing filters or a different search."
    }

    @ViewBuilder
    private func songRow(_ song: Song) -> some View {
        let inAnyPlaylist = store.isInAnyPlaylist(song)
        let others = store.otherPlaylistNamesContaining(song)
        HStack(alignment: .center, spacing: 10) {
            SongArtwork(genre: song.genre, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !others.isEmpty {
                    Text("Also in: \(others.joined(separator: ", "))")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
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
            .accessibilityIdentifier("catalog.preview.\(song.id.uuidString)")

            Button {
                songForPlaylistPicker = song
            } label: {
                Label(
                    inAnyPlaylist ? "In playlist" : "Add",
                    systemImage: inAnyPlaylist ? "checkmark.circle.fill" : "plus.circle.fill"
                )
                .labelStyle(.iconOnly)
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    inAnyPlaylist ? Color.green : PlaylistTheme.accent,
                    inAnyPlaylist ? Color.green.opacity(0.35) : Color.blue.opacity(0.25)
                )
                .accessibilityLabel("Add to playlist")
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("catalog.add.\(song.id.uuidString)")
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

            Button("Add to playlist…", systemImage: "plus.circle") {
                songForPlaylistPicker = song
            }
        }
    }

    private func sectionHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func scheduleDebouncedRemoteSearch() {
        searchError = nil
        debouncedRemoteTask?.cancel()

        let snapshot = query
        debouncedRemoteTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: remoteDebounceNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }

            let current = snapshot.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !current.isEmpty else {
                isDebouncingRemote = false
                remoteResults = []
                remoteHasMore = false
                nextRemoteOffset = 0
                lastRemoteQuery = ""
                isSearchingRemote = false
                isLoadingMoreRemote = false
                return
            }

            guard current == trimmedQuery else { return }

            isDebouncingRemote = false
            await fetchRemoteFirstPage()
        }
    }

    @MainActor
    private func fetchRemoteFirstPage() async {
        let current = trimmedQuery
        guard !current.isEmpty else { return }

        isDebouncingRemote = false
        searchError = nil
        isSearchingRemote = true
        isLoadingMoreRemote = false

        guard network.isConnected else {
            isSearchingRemote = false
            searchError = "You’re offline. Connect to search MusicBrainz."
            return
        }

        do {
            let page = try await musicClient.searchRecordingsPage(
                query: current,
                limit: remotePageSize,
                offset: 0
            )

            guard current == trimmedQuery else { return }

            remoteResults = page.songs
            lastRemoteQuery = current
            nextRemoteOffset = page.endIndex
            remoteHasMore = page.hasMore
            recent.recordQuery(current)
        } catch is CancellationError {
            // Debounced search replaced or task cancelled — leave state to the new request.
        } catch {
            remoteResults = []
            remoteHasMore = false
            if current == trimmedQuery {
                searchError = "Search failed. Check your connection and try again."
            }
        }

        isSearchingRemote = false
    }

    @MainActor
    private func fetchRemoteNextPage() async {
        guard remoteHasMore, !lastRemoteQuery.isEmpty else { return }
        guard trimmedQuery == lastRemoteQuery else { return }
        guard network.isConnected else {
            searchError = "Offline — can’t load more."
            return
        }

        isLoadingMoreRemote = true
        searchError = nil

        do {
            let page = try await musicClient.searchRecordingsPage(
                query: lastRemoteQuery,
                limit: remotePageSize,
                offset: nextRemoteOffset
            )

            guard trimmedQuery == lastRemoteQuery else { return }

            var seen = Set(remoteResults.map(\.id))
            for song in page.songs where !seen.contains(song.id) {
                remoteResults.append(song)
                seen.insert(song.id)
            }
            nextRemoteOffset = page.endIndex
            remoteHasMore = page.hasMore
        } catch is CancellationError {
        } catch {
            if trimmedQuery == lastRemoteQuery {
                searchError = "Could not load more. Try again."
            }
        }

        isLoadingMoreRemote = false
    }
}

#Preview {
    @Previewable @State var store = PlaylistStore(
        catalog: Song.previewCatalog,
        library: .emptyFirstPlaylist()
    )
    @Previewable @State var playback = PlaybackManager()
    @Previewable @State var net = NetworkReachability()
    @Previewable @State var recent = RecentSearchStore()

    BrowseView()
        .environment(store)
        .environment(playback)
        .environment(net)
        .environment(recent)
}
