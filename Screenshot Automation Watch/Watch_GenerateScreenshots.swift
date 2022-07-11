import SwiftUI
import XCTest

class Watch_GenerateScreenshots: XCTestCase {
    let app = XCUIApplication()

    enum Source: Int {
        case phone = 0
        case watch
    }

    override func setUpWithError() throws {
        continueAfterFailure = false

        setupSnapshot(app)
        app.launch()
        XCTAssert(app.wait(for: .runningForeground, timeout: 5))

        navigateBackToSourceSelection()

        // Refreshes App Data
        app.buttons.allElementsBoundByIndex[2].waitForThenTap()
    }

    func test_generateScreenshots() throws {
        snapshot("08_Source_Options")

        selectSource(.phone)
        snapshot("09_Phone_Source_Options")

        app.cells.allElementsBoundByIndex[0].waitForThenTap()
        XCUIDevice.shared.rotateDigitalCrown(delta: 3)

        snapshot("01_Phone_Source_Now_Playing")

        XCUIDevice.shared.rotateDigitalCrown(delta: -3)

        app.buttons["effects on"].waitForThenTap()
        snapshot("02_Effects")

        app.navigationBars.buttons.firstMatch.waitForThenTap()
        app.navigationBars.buttons.firstMatch.waitForThenTap()

        app.cells.allElementsBoundByIndex[2].waitForThenTap()
        let _ = app.cells.allElementsBoundByIndex[0].waitForExistence(timeout: 5)
        snapshot("05_Phone_Source_Filters")

        app.cells.allElementsBoundByIndex[0].waitForThenTap()

        // Wait for the episode to load
        let _ = app.images["episodegradient"].waitForExistence(timeout: 5)
        snapshot("06_Phone_Source_Filters_Expanded")

        selectSource(.watch)
        snapshot("03_Watch_Source_Options")

        app.cells.allElementsBoundByIndex[2].waitForThenTap()
        snapshot("04_Watch_Source_Podcasts")

        selectSource(.phone)
        app.cells.allElementsBoundByIndex[3].waitForThenTap()
        app.cells.allElementsBoundByIndex[0].waitForThenTap()
        snapshot("07_Phone_Source_Downloaded_Episode")

        selectSource(.watch)
        app.cells.allElementsBoundByIndex[3].waitForThenTap()
        app.cells.allElementsBoundByIndex[1].waitForThenTap()
        app.cells.allElementsBoundByIndex[1].waitForThenTap()
        snapshot("10_Watch_Source_Filters_Episode")
    }
}

extension Watch_GenerateScreenshots {
    private func selectSource(_ source: Source) {
        navigateBackToSourceSelection()
        app.buttons.allElementsBoundByIndex[source.rawValue].waitForThenTap()
    }

    private func navigateBackToSourceSelection() {
        _ = app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5)
        while app.navigationBars.buttons.allElementsBoundByIndex.count > 0 {
            app.navigationBars.buttons.firstMatch.waitForThenTap()
            _ = app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5)
        }
    }
}
