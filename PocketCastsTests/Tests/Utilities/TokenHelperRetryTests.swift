import Foundation
import PocketCastsUtils
import XCTest
@testable import PocketCastsServer

/// `TokenHelper` retries a request once after a 401 with a freshly acquired token. The retry used to
/// run inside the `URLSession` completion handler of the failed request, and `acquireToken()` blocks
/// on a semaphore until the token request completes. A session delivers its completion handlers on
/// one serial queue, so blocking inside one of them meant the token request's completion could never
/// run: the retry deadlocked, and so did every other request on that session (PCIOS-1224).
///
/// These tests drive a real `URLSession`, stubbed at the protocol level, so they exercise the serial
/// delegate queue the way production does. A fake that calls completions synchronously can't catch
/// the deadlock.
class TokenHelperRetryTests: XCTestCase {
    private static let email = "test@test.com"
    private static let freshToken = "fresh-token"

    private var readStateURL: URL { ServerHelper.asUrl(ServerConstants.Urls.api() + "user/whats_new/read_state/list") }
    private var loginURL: URL { ServerHelper.asUrl(ServerConstants.Urls.api() + "user/login") }

    private var tokenHelper: TokenHelper!

    override func setUp() {
        super.setUp()
        ServerSettings.setSyncingEmail(email: Self.email)
        ServerSettings.saveSyncingPassword("1234")
        ServerSettings.syncingV2Token = "expired-token"

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SerialStubURLProtocol.self]
        tokenHelper = TokenHelper(urlConnection: URLConnection(handler: URLSession(configuration: configuration)))
    }

    override func tearDown() {
        SerialStubURLProtocol.requestHandler = nil
        KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
        super.tearDown()
    }

    /// The expired token gets a 401, the login call issues a new one, and the retried request completes.
    func testRetryAfter401CompletesWithAFreshToken() throws {
        let readStateAuthorizations = LockedArray<String?>()
        let loginURL = loginURL
        let readStateURL = readStateURL

        SerialStubURLProtocol.requestHandler = { request in
            switch request.url {
            case loginURL:
                var object = Api_UserLoginResponse()
                object.token = Self.freshToken
                object.uuid = UUID().uuidString
                object.email = Self.email
                return (HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil)!, try object.serializedData())
            case readStateURL:
                let authorization = request.value(forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
                readStateAuthorizations.append(authorization)
                let statusCode = authorization == "Bearer \(Self.freshToken)" ? 200 : 401
                return (HTTPURLResponse(url: readStateURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!, Data())
            default:
                throw URLError(.unsupportedURL)
            }
        }

        let completed = expectation(description: "The retried request completes")
        tokenHelper.callSecureUrl(request: URLRequest(url: readStateURL)) { response, _, error in
            XCTAssertNil(error)
            XCTAssertEqual(response?.statusCode, 200)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 10)
        XCTAssertEqual(readStateAuthorizations.values, ["Bearer expired-token", "Bearer \(Self.freshToken)"])
        XCTAssertEqual(ServerSettings.syncingV2Token, Self.freshToken)
    }

    /// Same path through the async overload, which `WhatsNewReadStateTask` uses.
    func testAsyncRetryAfter401CompletesWithAFreshToken() async throws {
        let loginURL = loginURL
        let readStateURL = readStateURL

        SerialStubURLProtocol.requestHandler = { request in
            switch request.url {
            case loginURL:
                var object = Api_UserLoginResponse()
                object.token = Self.freshToken
                object.uuid = UUID().uuidString
                object.email = Self.email
                return (HTTPURLResponse(url: loginURL, statusCode: 200, httpVersion: nil, headerFields: nil)!, try object.serializedData())
            case readStateURL:
                let authorization = request.value(forHTTPHeaderField: ServerConstants.HttpHeaders.authorization)
                let statusCode = authorization == "Bearer \(Self.freshToken)" ? 200 : 401
                return (HTTPURLResponse(url: readStateURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!, Data())
            default:
                throw URLError(.unsupportedURL)
            }
        }

        let tokenHelper: TokenHelper = self.tokenHelper
        let request = URLRequest(url: readStateURL)
        let completed = expectation(description: "The retried request completes")
        let statusCode = LockedArray<Int?>()
        let call = Task {
            let (response, _) = try await tokenHelper.callSecureUrl(request: request)
            statusCode.append(response?.statusCode)
            completed.fulfill()
        }

        await fulfillment(of: [completed], timeout: 10)
        call.cancel()
        XCTAssertEqual(statusCode.values, [200], "The retried request never completed: the 401 retry is blocking the session's delegate queue")
    }
}

/// Answers every request on the session it's installed on with whatever `requestHandler` returns.
/// Responses still go through the session, so completion handlers run on its serial delegate queue.
private final class SerialStubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class LockedArray<Element>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = [Element]()

    var values: [Element] {
        lock.withLock { storage }
    }

    func append(_ element: Element) {
        lock.withLock { storage.append(element) }
    }
}
