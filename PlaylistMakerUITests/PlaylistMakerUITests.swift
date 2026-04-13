//
//  PlaylistMakerUITests.swift
//  PlaylistMakerUITests
//

import XCTest

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
        XCTAssertTrue(addButton.isHittable)
        addButton.tap()

        XCTAssertTrue(app.navigationBars["Add to playlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your playlists"].waitForExistence(timeout: 2))
        app.buttons["Favorites"].firstMatch.tap()
        app.navigationBars["Add to playlist"].buttons["Done"].tap()

        let addedButton = app.buttons["catalog.add.\(firstSongId)"]
        XCTAssertTrue(addedButton.waitForExistence(timeout: 2))
        XCTAssertTrue(addedButton.isEnabled)

        let stats = app.otherElements["statsStrip"]
        XCTAssertTrue(stats.waitForExistence(timeout: 2))
        XCTAssertTrue(stats.staticTexts["1"].exists)

        app.tabBars.buttons["Playlists"].tap()

        let playlistRoot = app.otherElements["playlistRoot"]
        XCTAssertTrue(playlistRoot.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Favorites"].waitForExistence(timeout: 2))
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
        XCTAssertTrue(addAgain.isEnabled)
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

        XCTAssertTrue(app.otherElements["statsStrip"].staticTexts["1"].waitForExistence(timeout: 2))
        toggle.tap()
        XCTAssertTrue(app.navigationBars["Add to playlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your playlists"].waitForExistence(timeout: 2))
        app.buttons["Favorites"].firstMatch.tap()
        app.navigationBars["Add to playlist"].buttons["Done"].tap()

        XCTAssertTrue(app.otherElements["statsStrip"].staticTexts["0"].waitForExistence(timeout: 2))
    }
}
