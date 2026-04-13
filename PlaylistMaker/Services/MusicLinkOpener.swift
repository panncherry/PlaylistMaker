//
//  MusicLinkOpener.swift
//  PlaylistMaker
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

enum MusicLinkOpener {
    static func openAppleMusicSearch(title: String, artist: String) {
        let q = "\(artist) \(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://music.apple.com/search?term=\(q)") else { return }
        openURL(url)
    }

    static func openSpotifySearch(title: String, artist: String) {
        let raw = "\(artist) \(title)"
        let path = raw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        if let spotify = URL(string: "spotify:search:\(path)") {
            #if os(iOS)
            if UIApplication.shared.canOpenURL(spotify) {
                UIApplication.shared.open(spotify)
                return
            }
            #endif
        }
        let webQ = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let u = URL(string: "https://open.spotify.com/search/\(webQ)") {
            openURL(u)
        }
    }

    private static func openURL(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}
