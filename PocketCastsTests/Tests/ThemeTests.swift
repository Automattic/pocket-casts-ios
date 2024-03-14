import Foundation
@testable import podcasts
import XCTest
@testable import PocketCastsUtils

class ThemeTests: XCTestCase {
    let flagMock = FeatureFlagMock()

    override func setUp() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.themeKey)
        flagMock.set(.newSettingsStorage, value: false)
    }

    override func tearDown() {
        flagMock.reset()
    }

    // If the user never changed the theme neither toggled light/dark option
    // Follow the system
    func testFollowSystemIfNoThemeWasSelected() {
        _ = Theme()

        XCTAssertTrue(Settings.shouldFollowSystemTheme())
    }

    // If the user has a previously selected theme
    // Don't follow the system light/dark mode
    func testFollowSystemIfThemeWasSelected() {
        UserDefaults.standard.set(1, forKey: Constants.UserDefaults.themeKey)
        _ = Theme()
        XCTAssertFalse(Settings.shouldFollowSystemTheme())
    }

    // If the user previously opted-out for following the system
    // Don't follow the system light/dark mode
    func testDontFollowSystemIfOptionWasSetBefore() {
        Settings.setShouldFollowSystemTheme(false)
        _ = Theme()
        XCTAssertFalse(Settings.shouldFollowSystemTheme())
    }

    // If the user previously opted-in for following the system
    // But never choose a theme, follow the system
    func testFollowSystemIfOptionWasSetBeforeButThemeWasntChosen() {
        Settings.setShouldFollowSystemTheme(true)

        _ = Theme()

        XCTAssertTrue(Settings.shouldFollowSystemTheme())
    }

    // If the user doesn't have a previously selected theme
    // We should follow system dark/light mode
    // Even if they change the theme later
    func testFollowSystemIfThemeIsSelected() {
        _ = Theme()

        XCTAssertTrue(Settings.shouldFollowSystemTheme())

        // User changes the theme
        UserDefaults.standard.set(1, forKey: Constants.UserDefaults.themeKey)

        _ = Theme()

        XCTAssertTrue(Settings.shouldFollowSystemTheme())
    }
}
