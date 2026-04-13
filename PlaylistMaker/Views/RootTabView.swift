//
//  RootTabView.swift
//  PlaylistMaker
//

import SwiftUI

struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(PlaybackManager.self) private var playback
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        TabView {
            BrowseView()
                .safeAreaInset(edge: .bottom, spacing: 6) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Browse", systemImage: "music.note.list")
                }
                .accessibilityIdentifier("tabBrowse")

            PlaylistsRootView()
                .safeAreaInset(edge: .bottom, spacing: 6) {
                    MiniPlayerView()
                }
                .tabItem {
                    Label("Playlists", systemImage: "list.bullet.rectangle")
                }
                .accessibilityIdentifier("tabPlaylists")
        }
        .tint(PlaylistTheme.accent)
        .background(
            ZStack {
                PlaylistTheme.headerGradient.opacity(0.18)
                Color(.systemGroupedBackground)
            }
            .ignoresSafeArea()
        )
        .onAppear {
            showOnboarding = !hasCompletedOnboarding
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                playback.pauseForBackground()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showOnboarding = false
            }
        }
    }
}

#Preview {
    @Previewable @State var store = PlaylistStore(catalog: Song.previewCatalog, library: .emptyFirstPlaylist())
    @Previewable @State var playback = PlaybackManager()
    @Previewable @State var net = NetworkReachability()
    @Previewable @State var recent = RecentSearchStore()

    RootTabView()
        .environment(store)
        .environment(playback)
        .environment(net)
        .environment(recent)
}
