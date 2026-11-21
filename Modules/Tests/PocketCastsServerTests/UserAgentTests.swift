@testable import PocketCastsServer
import XCTest

class UserAgentTests: XCTestCase {
    func testPublicUserAgentIdentifiesIOSOnly() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        XCTAssertEqual(ServerConstants.Values.appUserAgent, "Pocket Casts (iOS)")
        #else
        XCTAssertEqual(ServerConstants.Values.appUserAgent, "Pocket Casts")
        #endif
    }
}
