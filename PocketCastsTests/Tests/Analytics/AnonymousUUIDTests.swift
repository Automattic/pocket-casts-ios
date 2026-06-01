import XCTest

@testable import podcasts

final class AnonymousUUIDTests: XCTestCase {
    private let userDefaults = UserDefaults(suiteName: "AnonymousUUIDTests")
    private let key = "TracksAnonymousUUID"

    override func tearDownWithError() throws {
        let userDefaults = try XCTUnwrap(userDefaults)
        userDefaults.removeObject(forKey: key)
    }

    func testUUID() throws {
        let userDefaults = try XCTUnwrap(userDefaults)
        let uuid = UUID().uuidString
        userDefaults.set(uuid, forKey: key)
        XCTAssertEqual(AnonymousUUID.generate(userDefaults: userDefaults), uuid)
    }
}
