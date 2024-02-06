import XCTest
@testable import PocketCastsServer
import PocketCastsUtils

class SettingsStoreTests: XCTestCase {

    private struct TestType: JSONCodable {
        var name: String
    }

    private let userDefaultsSuiteName = "PocketCastsServer-SettingsStoreTests"
    private let defaultsKey = "app_settings"
    private let initialName = "Initial"
    private let changedName = "Changed"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    /// Tests the initial Empty state of the UserDefaults suite
    func testEmptyStore() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")

        XCTAssertNil(defaults.data(forKey: defaultsKey), "User Defaults data should not exist yet for \(defaultsKey)")
    }

    /// Tests the initial value taken from the SettingsStore.value
    func testInitialValue() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")

        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: TestType(name: initialName))

        XCTAssertEqual(store.settings.name, initialName, "Accessed initial value should match")
    }

    /// Tests updating values to a single SettingsStore instance
    func testValueUpdate() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: TestType(name: initialName))

        store.settings.name = changedName

        XCTAssertEqual(store.settings.name, changedName, "Accessed value should match changed value")
    }

    /// Tests loading values set to SettingsStore with a second instance
    func testFromUserDefaults() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: TestType(name: initialName))

        store.settings.name = changedName

        let secondStore = SettingsStore(userDefaults: defaults, key: defaultsKey, value: TestType(name: initialName))

        XCTAssertNotEqual(secondStore.settings.name, initialName, "Access value should fetch UserDefaults and not initial value of instance")
        XCTAssertEqual(secondStore.settings.name, changedName, "Accessed value on second reference should match changed value")
    }


}
