import XCTest
@testable import PocketCastsServer
import PocketCastsUtils

class SettingsStoreTests: XCTestCase {

    struct TestType: JSONCodable {
        var name: String
    }

    private let userDefaultsSuiteName = "PocketCastsServer-SettingsStoreTests"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    func testStore() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        let defaultsKey = "app_settings"

        XCTAssertNil(defaults.data(forKey: defaultsKey), "User Defaults data should not exist yet for \(defaultsKey)")

        let initialName = "Hello"

        let store = SettingsStore(userDefaults: defaults, key: defaultsKey, value: TestType(name: initialName))

        let changedName = "Changed"

        XCTAssertEqual(store.settings.name, initialName, "Accessed initial value should match")
        store.settings.name = changedName
        XCTAssertEqual(store.settings.name, changedName, "Accessed value should match changed value")

        let secondStore = SettingsStore(userDefaults: defaults, key: defaultsKey, value: TestType(name: initialName))
        XCTAssertNotEqual(secondStore.settings.name, initialName, "Access value should fetch UserDefaults and not initial value of instance")
        XCTAssertEqual(secondStore.settings.name, changedName, "Accessed value on second reference should match changed value")
    }
}
