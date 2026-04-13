//
//  PlaylistMakerApp.swift
//  PlaylistMaker
//
//  Created by Pann Cherry on 4/12/26.
//

import SwiftUI

@main
struct PlaylistMakerApp: App {
    @State private var playlistStore: PlaylistStore
    @State private var playbackManager = PlaybackManager()
    @State private var networkReachability = NetworkReachability()
    @State private var recentSearchStore = RecentSearchStore()

    init() {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        if ProcessInfo.processInfo.arguments.contains("-resetPlaylist") {
            LibraryFilePersistence.resetEverything()
        }
        _playlistStore = State(
            initialValue: PlaylistStore(catalog: CatalogLoader.loadBundledCatalog())
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(playlistStore)
                .environment(playbackManager)
                .environment(networkReachability)
                .environment(recentSearchStore)
        }
    }
}
