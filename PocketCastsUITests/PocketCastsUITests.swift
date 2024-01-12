//
//  PocketCastsUITests.swift
//  PocketCastsUITests
//
//  Created by Brandon Titus on 1/8/24.
//  Copyright © 2024 Shifty Jelly. All rights reserved.
//

import XCTest

final class PocketCastsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // We want all errors to be reported from accessibility audit
        continueAfterFailure = true

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPodcastsTab() throws {
        let app = XCUIApplication()
        app.launch()

        let tab = app.tab(.podcasts)
        guard tab.waitForExistence(timeout: 20.0) else { return }

        tab.tap()

        try app.performAccessibilityAudit(for: .dynamicType) { issue in
            if issue.element?.identifier.hasPrefix("GridCell") == true {
                return false
            }

            return true
        }
    }

    func testPodcastsListView() throws {
        let app = XCUIApplication()
        app.launch()

        let tab = app.tab(.podcasts)
        guard tab.waitForExistence(timeout: 20.0) else { return }
        tab.tap()

        let actionsButton = app.buttons["More actions"]
        guard actionsButton.waitForExistence(timeout: 20.0) else { return }
        actionsButton.tap()

        let listButton = app.buttons["List"]
        guard listButton.waitForExistence(timeout: 20.0) else { return }
        listButton.tap()

        let dismiss = app.buttons["Dismiss"]
        dismiss.tap()

        try app.performAccessibilityAudit()
    }

    func testFiltersTab() throws {
        let app = XCUIApplication()
        app.launch()

        let tab = app.tab(.filter)
        guard tab.waitForExistence(timeout: 0.5) else { return }

        tab.tap()

        try app.performAccessibilityAudit(for: .dynamicType)
    }

    func testDiscoverTab() throws {
        let app = XCUIApplication()
        app.launch()

        let tab = app.tab(.discover)
        guard tab.waitForExistence(timeout: 0.5) else { return }

        tab.tap()

        try app.performAccessibilityAudit(for: .dynamicType)
    }

    func testProfileTab() throws {
        let app = XCUIApplication()
        app.launch()

        let tab = app.tab(.profile)
        guard tab.waitForExistence(timeout: 0.5) else { return }

        tab.tap()

        try app.performAccessibilityAudit(for: .dynamicType)
    }

    func testNowPlayingScreen() throws {
        let app = XCUIApplication()
        app.launch()

        let playButton = app.buttons["Player"]
        guard playButton.waitForExistence(timeout: 0.5) else { return }

        playButton.tap()

        try app.performAccessibilityAudit(for: .dynamicType)
    }
}

extension XCUIApplication {
    enum PocketCastsTab: String {
        case podcasts = "Podcasts"
        case filter = "Filter"
        case discover = "Discover"
        case profile = "Profile"
    }

    func tab(_ tab: PocketCastsTab) -> XCUIElement {
        tabBars.firstMatch.buttons[tab.rawValue]
    }
}
