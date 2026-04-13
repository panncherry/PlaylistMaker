//
//  iTunesPreviewClient.swift
//  PlaylistMaker
//
//  iTunes Search API — metadata + 30s preview URLs (no API key).
//

import Foundation

enum iTunesPreviewClientError: Error {
    case invalidURL
    case httpFailure(Int)
    case decoding
}

/// Thread-safe wrapper around `URLSession` (no mutable shared state beyond the session).
final class iTunesPreviewClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns the first track's preview URL, if Apple exposes one for this search.
    func fetchPreviewURL(title: String, artist: String) async throws -> URL? {
        let q = "\(artist) \(title)".trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }

        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: q),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "1"),
        ]
        guard let url = components?.url else { throw iTunesPreviewClientError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw iTunesPreviewClientError.httpFailure(-1) }
        guard (200 ... 299).contains(http.statusCode) else { throw iTunesPreviewClientError.httpFailure(http.statusCode) }

        let decoded: iTunesSearchResponse
        do {
            decoded = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
        } catch {
            throw iTunesPreviewClientError.decoding
        }
        guard let track = decoded.results.first, let s = track.previewUrl, let preview = URL(string: s) else {
            return nil
        }
        return preview
    }
}

private struct iTunesSearchResponse: Decodable, Sendable {
    let results: [iTunesTrack]
}

private struct iTunesTrack: Decodable, Sendable {
    let previewUrl: String?
}
