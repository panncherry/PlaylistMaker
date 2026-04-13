//
//  RecentSearchStore.swift
//  PlaylistMaker
//

import Foundation
import Observation

@MainActor
@Observable
final class RecentSearchStore {
    private let key = "playlistMaker.recentSearches"
    private let maxItems = 15

    private(set) var queries: [String] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            queries = decoded
        }
    }

    func recordQuery(_ raw: String) {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return }
        queries.removeAll { $0.caseInsensitiveCompare(q) == .orderedSame }
        queries.insert(q, at: 0)
        if queries.count > maxItems {
            queries = Array(queries.prefix(maxItems))
        }
        persist()
    }

    func remove(_ q: String) {
        queries.removeAll { $0 == q }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(queries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
