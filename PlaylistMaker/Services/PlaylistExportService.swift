//
//  PlaylistExportService.swift
//  PlaylistMaker
//

import Foundation

enum PlaylistExportService {
    static func plainText(playlistName: String, songs: [Song]) -> String {
        var lines = ["\(playlistName)", String(repeating: "—", count: min(playlistName.count, 40)), ""]
        for (i, s) in songs.enumerated() {
            lines.append("\(i + 1). \(s.title) — \(s.artist) (\(s.genre)) · \(s.durationFormatted)")
        }
        return lines.joined(separator: "\n")
    }

    static func csv(songs: [Song]) -> String {
        var lines = ["Title,Artist,Genre,DurationSeconds"]
        for s in songs {
            let title = escapeCSV(s.title)
            let artist = escapeCSV(s.artist)
            let genre = escapeCSV(s.genre)
            lines.append("\(title),\(artist),\(genre),\(Int(s.durationSeconds))")
        }
        return lines.joined(separator: "\n")
    }

    private static func escapeCSV(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") {
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return s
    }
}
