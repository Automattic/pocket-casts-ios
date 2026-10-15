import XCTest
@testable import podcasts

final class GoogleSocialLoginTests: XCTestCase {
    func testMakeConfigurationThrowsWhenClientIDIsEmpty() {
        XCTAssertThrowsError(try GoogleSocialLogin.makeConfiguration(clientID: "", serverClientID: "server-client-id")) { error in
            XCTAssertEqual(error as? GoogleSocialLoginError, .missingClientID)
        }
    }

    func testMakeConfigurationUsesProvidedClientIDs() throws {
        let configuration = try GoogleSocialLogin.makeConfiguration(clientID: "client-id", serverClientID: "server-client-id")

        XCTAssertEqual(configuration.clientID, "client-id")
        XCTAssertEqual(configuration.serverClientID, "server-client-id")
    }
}
