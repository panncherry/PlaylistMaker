//
//  PlaybackManager.swift
//  PlaylistMaker
//

import AVFoundation
import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PlaybackManager: NSObject {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private let iTunes = iTunesPreviewClient()

    /// Invalidates in-flight async work when starting new playback.
    private var playbackSession = UUID()

    /// Active playlist queue (Play all / Shuffle). Empty when playing a single chosen track only.
    private var queue: [Song] = []
    /// Index of the song currently loading or playing within `queue`.
    private var queueIndex: Int = 0

    private(set) var isPlaying = false
    /// The track the UI should show (updated immediately when switching, so the mini player never collapses).
    private(set) var nowPlaying: Song?
    /// True while resolving URL / preparing the next item (optional subtle UI).
    private(set) var isPreparing = false

    /// When non-nil, previews are advancing through a playlist (`current` is 1-based).
    var queueProgress: (current: Int, total: Int)? {
        guard !queue.isEmpty else { return nil }
        let total = queue.count
        let current = min(max(queueIndex + 1, 1), total)
        return (current, total)
    }

    /// True while a Play all / Shuffle queue session exists (playing, paused, or loading the next track).
    var isQueuePlaybackActive: Bool {
        !queue.isEmpty
    }

    /// Pauses or resumes the current **queue** session. Ignored when not in queue mode or while resolving the next URL.
    func toggleQueuePlayPause() {
        guard !queue.isEmpty, !isPreparing else { return }
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            guard player != nil else { return }
            if UIApplication.shared.applicationState == .active {
                player?.play()
                isPlaying = true
            }
        }
    }

    /// Whether Previous is available (queue mode only). On the first track, still goes to start of the preview.
    var canSkipToPreviousInQueue: Bool {
        isQueuePlaybackActive && !isPreparing
    }

    /// Whether Next can move to another track (disabled on the last track).
    var canSkipToNextInQueue: Bool {
        guard isQueuePlaybackActive, !isPreparing else { return false }
        return queueIndex < queue.count - 1
    }

    /// Previous track, or restarts the current preview from the beginning on the first track.
    func skipToPreviousInQueue() {
        guard canSkipToPreviousInQueue else { return }
        let session = playbackSession
        if queueIndex > 0 {
            Task { await playQueueSong(at: queueIndex - 1, session: session) }
        } else {
            restartCurrentTrackAtBeginning()
        }
    }

    /// Skips to the next queued preview, or ends the queue on the last track.
    func skipToNextInQueue() {
        guard isQueuePlaybackActive, !isPreparing else { return }
        let session = playbackSession
        let next = queueIndex + 1
        guard next < queue.count else {
            finishQueuePlaybackAndStop()
            return
        }
        Task { await playQueueSong(at: next, session: session) }
    }

    private func restartCurrentTrackAtBeginning() {
        guard let currentPlayer = player else { return }
        currentPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            guard finished else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.player === currentPlayer else { return }
                if UIApplication.shared.applicationState == .active {
                    currentPlayer.play()
                    self.isPlaying = true
                }
            }
        }
    }

    func togglePreview(for song: Song) async {
        let session = beginPlaybackSession()
        clearQueue()

        if nowPlaying?.id == song.id, isPlaying {
            stop()
            return
        }

        teardownPlayerOnly()

        nowPlaying = song
        isPlaying = false
        isPreparing = true

        if let urlString = song.previewURL, let u = URL(string: urlString) {
            guard session == playbackSession else { return }
            attachAndPlay(
                url: u,
                song: song,
                onEnded: { [weak self] in
                    self?.stop()
                }
            )
            return
        }

        do {
            guard let url = try await iTunes.fetchPreviewURL(title: song.title, artist: song.artist) else {
                guard session == playbackSession, nowPlaying?.id == song.id else { return }
                isPreparing = false
                nowPlaying = nil
                return
            }
            guard session == playbackSession, nowPlaying?.id == song.id else { return }
            attachAndPlay(
                url: url,
                song: song,
                onEnded: { [weak self] in
                    self?.stop()
                }
            )
        } catch {
            guard session == playbackSession, nowPlaying?.id == song.id else { return }
            isPreparing = false
            nowPlaying = nil
        }
    }

    /// Plays previews for every song in order, advancing when each preview ends.
    func playAllPreviews(songs: [Song]) async {
        await startQueuePlayback(songs: songs, shuffled: false)
    }

    /// Plays previews in a random order (shuffled copy), advancing through the list.
    func shuffleAndPlayPreviews(songs: [Song]) async {
        await startQueuePlayback(songs: songs, shuffled: true)
    }

    private func startQueuePlayback(songs: [Song], shuffled: Bool) async {
        guard !songs.isEmpty else { return }
        let session = beginPlaybackSession()
        teardownPlayerOnly()
        queue = shuffled ? songs.shuffled() : Array(songs)
        queueIndex = 0
        await playQueueSong(at: 0, session: session)
    }

    private func playQueueSong(at index: Int, session: UUID) async {
        guard session == playbackSession else { return }
        guard index < queue.count else {
            finishQueuePlaybackAndStop()
            return
        }

        queueIndex = index
        let song = queue[index]

        nowPlaying = song
        isPlaying = false
        isPreparing = true

        if let urlString = song.previewURL, let u = URL(string: urlString) {
            guard session == playbackSession else { return }
            attachAndPlay(
                url: u,
                song: song,
                onEnded: { [weak self] in
                    self?.advanceQueueAfterTrackEnded(session: session)
                }
            )
            return
        }

        do {
            guard let url = try await iTunes.fetchPreviewURL(title: song.title, artist: song.artist) else {
                guard session == playbackSession else { return }
                await advanceQueueAfterFailedLoad(session: session)
                return
            }
            guard session == playbackSession, nowPlaying?.id == song.id else { return }
            attachAndPlay(
                url: url,
                song: song,
                onEnded: { [weak self] in
                    self?.advanceQueueAfterTrackEnded(session: session)
                }
            )
        } catch {
            guard session == playbackSession else { return }
            await advanceQueueAfterFailedLoad(session: session)
        }
    }

    private func advanceQueueAfterTrackEnded(session: UUID) {
        guard session == playbackSession else { return }
        let next = queueIndex + 1
        guard next < queue.count else {
            finishQueuePlaybackAndStop()
            return
        }
        Task { await playQueueSong(at: next, session: session) }
    }

    private func advanceQueueAfterFailedLoad(session: UUID) async {
        guard session == playbackSession else { return }
        let next = queueIndex + 1
        guard next < queue.count else {
            finishQueuePlaybackAndStop()
            return
        }
        await playQueueSong(at: next, session: session)
    }

    private func finishQueuePlaybackAndStop() {
        queue = []
        queueIndex = 0
        teardownPlayerOnly()
        isPlaying = false
        isPreparing = false
        nowPlaying = nil
    }

    @discardableResult
    private func beginPlaybackSession() -> UUID {
        let s = UUID()
        playbackSession = s
        return s
    }

    private func clearQueue() {
        queue = []
        queueIndex = 0
    }

    private func teardownPlayerOnly() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player?.pause()
        player = nil
    }

    private func attachAndPlay(url: URL, song: Song, onEnded: @escaping @MainActor () -> Void) {
        teardownPlayerOnly()
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        player = p
        nowPlaying = song
        isPreparing = false
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            Task { @MainActor in
                onEnded()
            }
        }
        if UIApplication.shared.applicationState == .active {
            p.play()
            isPlaying = true
        } else {
            p.pause()
            isPlaying = false
        }
    }

    /// Stops audio when leaving the foreground. Keeps `nowPlaying` and the player so the mini player stays stable.
    func pauseForBackground() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        beginPlaybackSession()
        clearQueue()
        teardownPlayerOnly()
        isPlaying = false
        isPreparing = false
        nowPlaying = nil
    }
}
