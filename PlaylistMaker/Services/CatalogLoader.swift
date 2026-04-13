//
//  CatalogLoader.swift
//  PlaylistMaker
//

import Foundation

enum CatalogLoader {
    static func loadBundledCatalog() -> [Song] {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return Song.previewCatalog
        }
        return (try? JSONDecoder().decode([Song].self, from: data)) ?? Song.previewCatalog
    }
}
