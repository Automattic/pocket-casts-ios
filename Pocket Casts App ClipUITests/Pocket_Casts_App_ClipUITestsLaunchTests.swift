//
//  Pocket_Casts_App_ClipUITestsLaunchTests.swift
//  Pocket Casts App ClipUITests
//
//  Created by Brandon Titus on 11/18/24.
//  Copyright © 2024 Shifty Jelly. All rights reserved.
//

import XCTest

final class Pocket_Casts_App_ClipUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
