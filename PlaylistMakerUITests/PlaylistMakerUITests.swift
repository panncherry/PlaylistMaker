//
//  PlaylistMakerUITests.swift
//  PlaylistMakerUITests
//

import XCTest

private extension XCUIApplication {
    func statsStripElement() -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "statsStrip")).firstMatch
    }

    /// SwiftUI `List` is usually exposed as `Table`; some builds use `CollectionView`.
    func playlistRootElement() -> XCUIElement {
        let pred = NSPredicate(format: "identifier == %@", "playlistRoot")
        return tables.matching(pred).firstMatch
    }

    /// Waits for the Playlists tab: nav bar, then list id **or** visible section rows.
    func waitForPlaylistsTabReady(timeout: TimeInterval = 15) -> Bool {
        guard navigationBars["Playlists"].waitForExistence(timeout: timeout) else { return false }
        let pred = NSPredicate(format: "identifier == %@", "playlistRoot")
        let slice = min(8.0, timeout)
        if tables.matching(pred).firstMatch.waitForExistence(timeout: slice) { return true }
        if collectionViews.matching(pred).firstMatch.waitForExistence(timeout: slice) { return true }
        if descendants(matching: .any).matching(pred).firstMatch.waitForExistence(timeout: slice) { return true }
        return staticTexts["Your playlists"].waitForExistence(timeout: timeout)
            && staticTexts["Favorites"].waitForExistence(timeout: timeout)
    }
}

/// Song count is exposed on the strip via `accessibilityValue` (nested Text ids are lost in List).
private func XCTAssertStatsSongCount(_ strip: XCUIElement, equals expected: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(strip.waitForExistence(timeout: 12), "statsStrip should appear", file: file, line: line)
    let fromValue: String = {
        if let s = strip.value as? String { return s }
        if let n = strip.value as? NSNumber { return n.stringValue }
        if let n = strip.value as? Int { return String(n) }
        return ""
    }()
    if fromValue == expected {
        return
    }
    // Some SwiftUI/OS builds merge label + value into `label` (avoid `contains` — "10" contains "0").
    let label = strip.label
    if label == expected {
        return
    }
    let merged = "Playlist statistics, \(expected)"
    if label == merged || label == "Playlist statistics \(expected)" {
        return
    }
    XCTFail("Expected song count \(expected); value=\(String(describing: strip.value)) label=\(label)", file: file, line: line)
}

final class PlaylistMakerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddSongUpdatesStatsAndPlaylistTab() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetPlaylist", "-uiTesting"]
        app.launch()

        let firstSongId = "A1000000-0000-4000-8000-000000000001"
        let addButton = app.buttons["catalog.add.\(firstSongId)"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add to playlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your playlists"].waitForExistence(timeout: 2))
        app.buttons["Favorites"].firstMatch.tap()
        app.navigationBars["Add to playlist"].buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 8))
        let addedButton = app.buttons["catalog.add.\(firstSongId)"]
        XCTAssertTrue(addedButton.waitForExistence(timeout: 2))

        XCTAssertStatsSongCount(app.statsStripElement(), equals: "1")

        app.tabBars.buttons["Playlists"].tap()

        XCTAssertTrue(app.waitForPlaylistsTabReady(timeout: 15), "Playlists tab should show list or section content")
        app.staticTexts["Favorites"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Neon Skyline"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testRemoveSongFromPlaylistUpdatesBrowseButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetPlaylist", "-uiTesting"]
        app.launch()

        let firstSongId = "A1000000-0000-4000-8000-000000000001"
        app.buttons["catalog.add.\(firstSongId)"].tap()
        XCTAssertTrue(app.navigationBars["Add to playlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your playlists"].waitForExistence(timeout: 2))
        app.buttons["Favorites"].firstMatch.tap()
        app.navigationBars["Add to playlist"].buttons["Done"].tap()

        app.tabBars.buttons["Playlists"].tap()
        XCTAssertTrue(app.staticTexts["Favorites"].waitForExistence(timeout: 2))
        app.staticTexts["Favorites"].firstMatch.tap()
        XCTAssertTrue(app.buttons["playlist.remove.\(firstSongId)"].waitForExistence(timeout: 2))
        app.buttons["playlist.remove.\(firstSongId)"].tap()

        app.tabBars.buttons["Browse"].tap()
        let addAgain = app.buttons["catalog.add.\(firstSongId)"]
        XCTAssertTrue(addAgain.waitForExistence(timeout: 2))
    }

    @MainActor
    func testCheckmarkOnBrowseRemovesFromPlaylist() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetPlaylist", "-uiTesting"]
        app.launch()

        let firstSongId = "A1000000-0000-4000-8000-000000000001"
        let toggle = app.buttons["catalog.add.\(firstSongId)"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
        XCTAssertTrue(app.navigationBars["Add to playlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your playlists"].waitForExistence(timeout: 2))
        app.buttons["Favorites"].firstMatch.tap()
        app.navigationBars["Add to playlist"].buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 8))
        XCTAssertStatsSongCount(app.statsStripElement(), equals: "1")
        toggle.tap()
        XCTAssertTrue(app.navigationBars["Add to playlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your playlists"].waitForExistence(timeout: 2))
        app.buttons["Favorites"].firstMatch.tap()
        app.navigationBars["Add to playlist"].buttons["Done"].tap()

        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 8))
        XCTAssertStatsSongCount(app.statsStripElement(), equals: "0")
    }
}
