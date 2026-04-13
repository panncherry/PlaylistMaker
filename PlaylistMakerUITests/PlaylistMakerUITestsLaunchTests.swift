//
//  PlaylistMakerUITestsLaunchTests.swift
//  PlaylistMakerUITests
//
//  Created by Pann Cherry on 4/12/26.
//

import XCTest

final class PlaylistMakerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetPlaylist", "-uiTesting"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Browse"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
