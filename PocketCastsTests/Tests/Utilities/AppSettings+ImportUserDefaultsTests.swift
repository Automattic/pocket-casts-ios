import XCTest
import Foundation
import PocketCastsUtils
@testable import PocketCastsServer
@testable import podcasts

class AppSettingsImportUserDefaultsTests: XCTestCase {
    private let userDefaultsSuiteName = "PocketCastsServer-AppSettingsSyncUserDefaultsTests"
    private let defaultsKey = "app_settings"

    // Initial values for testing
    private let initialOpenLinks = false
    private let newOpenLinks = true
    private let initialRowAction = PrimaryRowAction.stream
    private let newRowAction = PrimaryRowAction.download

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    /// Set up UserDefaults instance with initial preset values.
    /// - Returns: An unwrapped `UserDefaults` instance with initial values set
    private func setupDefaults() throws -> UserDefaults {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")

        // Set up new values to update from
        defaults.set(newOpenLinks, forKey: Constants.UserDefaults.openLinksInExternalBrowser)
        defaults.set(newRowAction.rawValue, forKey: Settings.primaryRowActionKey)

        return defaults
    }

    /// Tests migrating from values stored in `NSUserDefaults` to `SettingsStore<AppSettings>`
    func testValueMigration() throws {
        let defaults = try setupDefaults()
        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: AppSettings.defaults)

        store.importUserDefaults(defaults)

        XCTAssertEqual(store.openLinks, newOpenLinks, "Value of openLinks should change after update")
        XCTAssertEqual(store.rowAction, newRowAction, "Value of rowAction should change after update")
    }
}
