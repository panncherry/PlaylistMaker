//
//  MiniPlayerView.swift
//  PlaylistMaker
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) private var playback

    var body: some View {
        if let song = playback.nowPlaying {
            HStack(alignment: .center, spacing: 10) {
                Group {
                    if playback.isPreparing {
                        ProgressView()
                            .scaleEffect(0.75)
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: playback.isPlaying ? "waveform" : "music.note")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(PlaylistTheme.accent)
                            .frame(width: 22, height: 22)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Preview")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        if let q = playback.queueProgress {
                            Text("· \(q.current)/\(q.total)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.tertiary)
                                .accessibilityLabel("Track \(q.current) of \(q.total)")
                        }
                    }

                    trackTitleLine(title: song.title, artist: song.artist)
                }

                Spacer(minLength: 4)

                if playback.queueProgress != nil {
                    HStack(spacing: 8) {
                        Button {
                            playback.skipToPreviousInQueue()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(minWidth: 32, minHeight: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(PlaylistTheme.accent)
                        .disabled(!playback.canSkipToPreviousInQueue)
                        .accessibilityLabel("Previous track")

                        Button {
                            playback.skipToNextInQueue()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(minWidth: 32, minHeight: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(PlaylistTheme.accent)
                        .disabled(!playback.canSkipToNextInQueue)
                        .accessibilityLabel("Next track")
                    }
                }

                Button {
                    playback.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(PlaylistTheme.accent, in: Circle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Stop playback")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .padding(.horizontal, 12)
            .accessibilityIdentifier("miniPlayer")
            .animation(.easeInOut(duration: 0.2), value: song.id)
            .animation(.easeInOut(duration: 0.15), value: playback.isPreparing)
        }
    }

    private func trackTitleLine(title: String, artist: String) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
            Text(" · ")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(artist)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}
