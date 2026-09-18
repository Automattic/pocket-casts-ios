import Foundation
import XCTest
@testable import PocketCastsServer

fileprivate extension URL {
    static var userLogin: URL {
        return ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login")
    }
    static var userUpdate: URL {
        return ServerHelper.asUrl(ServerConstants.Urls.main() + "user/update")
    }
}

class TokenHelperTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        SyncManager.clearTokensFromKeyChain()
        ServerSettings.setSyncingEmail(email: nil)
        ServerSettings.userId = nil
    }

    func testTokenCleanUpSilentlyRemovesStaleCredentials() {
        // Simulate stale keychain state: email exists but no password or refresh token.
        // This can happen with old installs where the keychain data survives but the
        // account no longer exists on the server.
        ServerSettings.setSyncingEmail(email: "stale@example.com")
        XCTAssertTrue(SyncManager.isUserLoggedIn())

        var signOutNotificationPosted = false
        let observer = NotificationCenter.default.addObserver(
            forName: .serverUserWillBeSignedOut,
            object: nil,
            queue: nil
        ) { _ in
            signOutNotificationPosted = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let tokenHelper = TokenHelper(urlConnection: URLConnection { _ in
            throw NSError(domain: "test", code: -1)
        })

        // acquireToken() must run off the main thread because it internally
        // dispatches to main to check application state and waits on a semaphore.
        let expectation = XCTestExpectation(description: "acquireToken completes")
        var token: String?
        DispatchQueue.global().async {
            token = tokenHelper.acquireToken()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)

        XCTAssertNil(token, "Should not acquire a token with stale credentials")
        XCTAssertFalse(signOutNotificationPosted, "Should not show sign-out alert for stale credentials")
        XCTAssertFalse(SyncManager.isUserLoggedIn(), "Stale login state should be cleared")
    }

    /// Tests the acquirePasswordToken function
    func testAcquirePasswordToken() {
        ServerSettings.setSyncingEmail(email: "test@test.com")
        ServerSettings.saveSyncingPassword("1234")

        let tokenHelper = TokenHelper(urlConnection: URLConnection { request in
            let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login")
            if request.url == url {
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
                var object = Api_UserLoginResponse()
                object.token = "1234"
                object.uuid = UUID().uuidString
                object.email = "test@test.com"
                let data = try object.serializedData()
                return (data, response)
            } else {
                throw NSError()
            }
        })
        do {
            let response = try tokenHelper.acquirePasswordToken()
            XCTAssertEqual(response?.token, "1234")
            XCTAssertEqual(response?.email, "test@test.com")
            XCTAssertNotNil(response?.uuid, "Should receive UUID")
        } catch {
            XCTFail("Acquire Password Token shouldn't fail: \(error)")
        }
    }

    /// Tests the acquireAsyncToken function with
    func testAcquireAsyncToken() {
        ServerSettings.setSyncingEmail(email: "test@test.com")
        ServerSettings.saveSyncingPassword("1234")

        let tokenHelper = TokenHelper(urlConnection: URLConnection { request in
            let url = ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login")
            if request.url == url {
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
                var object = Api_UserLoginResponse()
                object.token = "1234"
                object.uuid = UUID().uuidString
                object.email = "test@test.com"
                let data = try object.serializedData()
                return (data, response)
            } else {
                throw NSError()
            }
        })

        let expectation = XCTestExpectation(description: "Waiting on asyncAcquireToken to complete")
        tokenHelper.asyncAcquireToken { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response?.token, "1234")
                XCTAssertEqual(response?.email, "test@test.com")
                XCTAssertNotNil(response?.uuid, "Should receive UUID")
            case .failure(let error):
                XCTFail("Failed async acquire with error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    func testCallSecureURL() {

        ServerSettings.setSyncingEmail(email: "test@test.com")
        ServerSettings.saveSyncingPassword("1234")

        let tokenHelper = TokenHelper(urlConnection: URLConnection { request in
            switch request.url {
            case URL.userLogin:
                let response = HTTPURLResponse(url: .userLogin, statusCode: 200, httpVersion: nil, headerFields: nil)
                var object = Api_UserLoginResponse()
                object.token = "1234"
                object.uuid = UUID().uuidString
                object.email = "test@test.com"
                let data = try object.serializedData()
                return (data, response)
            case URL.userUpdate:
                let response = HTTPURLResponse(url: .userUpdate, statusCode: 200, httpVersion: nil, headerFields: nil)
                // Any data will do here, just to see if it makes it through
                let data = "Test".data(using: .utf8)
                return (data, response)
            default:
                throw NSError()
            }
        })

        let expectation = XCTestExpectation(description: "Waiting on asyncAcquireToken to complete")
        tokenHelper.callSecureUrl(request: URLRequest(url: .userUpdate)) { response, data, error in
            if let error {
                XCTFail("Failed async acquire with error: \(error)")
            } else {
                XCTAssertNotNil(response, "Should have received response")
                XCTAssertNotNil(data, "Should have received data")
            }
            expectation.fulfill()
        }
        wait(for: [expectation])
    }
}
