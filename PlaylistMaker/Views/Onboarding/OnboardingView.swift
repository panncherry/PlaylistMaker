//
//  OnboardingView.swift
//  PlaylistMaker
//

import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                OnboardingPage(
                    title: "Browse & search",
                    subtitle: "Filter the featured library, search MusicBrainz for online metadata, and preview clips when available.",
                    systemImage: "music.note.list"
                )
                .tag(0)

                OnboardingPage(
                    title: "Playlists",
                    subtitle: "Create multiple playlists, add songs once per list, and export or open tracks in Apple Music or Spotify.",
                    systemImage: "heart.text.square"
                )
                .tag(1)

                OnboardingPage(
                    title: "Privacy",
                    subtitle: "Your playlists stay on this device. Streaming previews use Apple’s public iTunes Search API; online search uses MusicBrainz.",
                    systemImage: "lock.shield"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: 420)

            Button {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    onFinished()
                }
            } label: {
                Text(page < 2 ? "Next" : "Get started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(PlaylistTheme.accent)
            .padding(.horizontal, 24)

            if page < 2 {
                Button("Skip") {
                    onFinished()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 32)
        .background(Color(.systemGroupedBackground))
    }
}

private struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(PlaylistTheme.headerGradient)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
