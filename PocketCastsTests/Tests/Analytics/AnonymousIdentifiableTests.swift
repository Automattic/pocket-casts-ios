import XCTest

@testable import podcasts

final class AnonymousIdentifiableTests: XCTestCase {
    private let userDefaults = UserDefaults(suiteName: "AnonymousIdentifiableTests")
    private let key = "TracksAnonymousUUID"

    override func tearDownWithError() throws {
        let userDefaults = try XCTUnwrap(userDefaults)
        userDefaults.removeObject(forKey: key)
    }

    func testUUID() throws {
        let userDefaults = try XCTUnwrap(userDefaults)
        let uuid = UUID().uuidString
        userDefaults.set(uuid, forKey: key)
        let anonymousIdentifiable = AnonymousIdentifiableMock(userDefaults: userDefaults)
        XCTAssertEqual(anonymousIdentifiable.anonymousUUID, uuid)
    }
}

fileprivate struct AnonymousIdentifiableMock: AnonymousIdentifiable {
    var anonymousUUID: String {
        generateAnonymousUUID()
    }

    let userDefaults: UserDefaults

    init(
        userDefaults: UserDefaults
    ) {
        self.userDefaults = userDefaults
    }
}
