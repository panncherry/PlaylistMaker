//
//  MusicBrainzClient.swift
//  PlaylistMaker
//
//  MusicBrainz Web Service: https://musicbrainz.org/doc/MusicBrainz_API
//  No API key required; requests must include a descriptive User-Agent.
//

import CryptoKit
import Foundation

enum MusicBrainzClientError: Error, Equatable {
    case invalidURL
    case httpFailure(Int)
    case decoding
}

/// One page of MusicBrainz recording search results (supports offset pagination).
nonisolated struct MusicBrainzRecordingSearchPage: Sendable {
    var songs: [Song]
    /// Total matches reported by the API (may be larger than `songs.count`).
    var totalCount: Int
    /// Offset used for this request.
    var offset: Int
    /// Page size requested.
    var limit: Int

    var endIndex: Int { offset + songs.count }

    var hasMore: Bool {
        if totalCount > 0 {
            return endIndex < totalCount
        }
        // If the API omits count, assume more when we received a full page.
        return songs.count >= limit
    }
}

/// Fetches recording metadata from the public MusicBrainz API (HTTPS, no API key).
actor MusicBrainzClient {
    private let session: URLSession
    private let userAgent: String
    private var lastRequestDate: Date = .distantPast

    init(
        session: URLSession = .shared,
        userAgent: String = "PlaylistMaker/1.0 (contact: https://github.com)"
    ) {
        self.session = session
        self.userAgent = userAgent
    }

    /// Searches recordings with `offset` for pagination (`limit` max 100 per MusicBrainz docs; we cap at 50 to stay polite).
    func searchRecordingsPage(query: String, limit: Int = 20, offset: Int = 0) async throws -> MusicBrainzRecordingSearchPage {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return MusicBrainzRecordingSearchPage(songs: [], totalCount: 0, offset: 0, limit: limit)
        }

        let safeLimit = min(max(limit, 1), 50)
        let safeOffset = max(0, offset)

        // MusicBrainz requests polite rate limiting (~1 req / sec per client).
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestDate)
        if elapsed < 1.05 {
            try await Task.sleep(nanoseconds: UInt64((1.05 - elapsed) * 1_000_000_000))
        }

        var components = URLComponents(string: "https://musicbrainz.org/ws/2/recording")
        components?.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "\(safeLimit)"),
            URLQueryItem(name: "offset", value: "\(safeOffset)"),
        ]
        guard let url = components?.url else { throw MusicBrainzClientError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        lastRequestDate = Date()
        guard let http = response as? HTTPURLResponse else { throw MusicBrainzClientError.httpFailure(-1) }
        guard (200 ... 299).contains(http.statusCode) else { throw MusicBrainzClientError.httpFailure(http.statusCode) }

        let decoded: MBRecordingSearchResponse
        do {
            decoded = try await Task.detached {
                try JSONDecoder().decode(MBRecordingSearchResponse.self, from: data)
            }.value
        } catch {
            throw MusicBrainzClientError.decoding
        }

        let songs = decoded.recordings.compactMap(Self.mapRecording)
        let total = decoded.count ?? songs.count
        return MusicBrainzRecordingSearchPage(
            songs: songs,
            totalCount: total,
            offset: safeOffset,
            limit: safeLimit
        )
    }

    private nonisolated static func mapRecording(_ recording: MBRecording) -> Song? {
        let title = recording.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let artist = formattedArtist(from: recording.artistCredit)

        let seconds: TimeInterval
        if let ms = recording.length, ms > 0 {
            seconds = TimeInterval(ms) / 1000.0
        } else {
            seconds = 0
        }

        let id = stableUUID(for: recording.id)
        return Song(
            id: id,
            title: title,
            artist: artist,
            genre: "MusicBrainz",
            durationSeconds: seconds
        )
    }

    private nonisolated static func formattedArtist(from credits: [MBCredit]?) -> String {
        guard let credits, !credits.isEmpty else { return "Unknown Artist" }
        let names = credits.compactMap { credit -> String? in
            let primary = credit.artist?.name ?? credit.name
            let trimmed = primary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        if names.isEmpty { return "Unknown Artist" }
        return names.joined(separator: ", ")
    }

    /// Deterministic UUID derived from MusicBrainz recording id for stable identity across launches.
    private nonisolated static func stableUUID(for musicBrainzId: String) -> UUID {
        let digest = Insecure.MD5.hash(data: Data("musicbrainz.recording.\(musicBrainzId)".utf8))
        var bytes = Array(digest)
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

// MARK: - JSON (subset)

private nonisolated struct MBRecordingSearchResponse: Decodable, Sendable {
    let count: Int?
    let recordings: [MBRecording]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        count = try c.decodeIfPresent(Int.self, forKey: .count)
        recordings = try c.decodeIfPresent([MBRecording].self, forKey: .recordings) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case count
        case recordings
    }
}

private nonisolated struct MBRecording: Decodable, Sendable {
    let id: String
    let title: String
    let length: Int?
    let artistCredit: [MBCredit]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case length
        case artistCredit = "artist-credit"
    }
}

private nonisolated struct MBCredit: Decodable, Sendable {
    let name: String?
    let artist: MBArtist?
}

private nonisolated struct MBArtist: Decodable, Sendable {
    let name: String
}
