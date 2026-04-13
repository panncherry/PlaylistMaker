//
//  ContentView.swift
//  PlaylistMaker
//
//  Created by Pann Cherry on 4/12/26.
//

import SwiftUI

/// Legacy entry retained for SwiftUI previews; the app uses `RootTabView`.
struct ContentView: View {
    @State private var store = PlaylistStore(catalog: CatalogLoader.loadBundledCatalog())
    @State private var playback = PlaybackManager()
    @State private var network = NetworkReachability()
    @State private var recent = RecentSearchStore()

    var body: some View {
        RootTabView()
            .environment(store)
            .environment(playback)
            .environment(network)
            .environment(recent)
    }
}

#Preview {
    ContentView()
}
