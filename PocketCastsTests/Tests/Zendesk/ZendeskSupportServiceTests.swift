import Combine
import Foundation
import PocketCastsUtils
import XCTest
@testable import podcasts

final class ZendeskSupportServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        ZendeskURLProtocol.requestHandler = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testServerErrorPreservesUTF8WhenExcerptLimitSplitsScalarBytes() {
        let expectedExcerpt = "description: " + String(repeating: "a", count: 242) + "é"
        let body = #"{"description":"\#(String(repeating: "a", count: 242))é"}"#
        ZendeskURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        let completionExpectation = expectation(description: "Request completes")
        var receivedError: ZendeskSupportService.SupportRequestError?

        makeService()
            .submitSupportRequest(makeSupportRequest())
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    receivedError = error as? ZendeskSupportService.SupportRequestError
                }
                completionExpectation.fulfill()
            }, receiveValue: { _ in
                XCTFail("Expected the request to fail")
            })
            .store(in: &cancellables)

        wait(for: [completionExpectation], timeout: 1)

        guard case let .serverError(statusCode, bodyExcerpt) = receivedError else {
            XCTFail("Expected a server error")
            return
        }
        XCTAssertEqual(statusCode, 400)
        XCTAssertEqual(bodyExcerpt, expectedExcerpt)
    }

    func testServerErrorOnlyIncludesSanitizedDocumentedJSONFields() {
        let body = """
        {
          "error": "RecordInvalid",
          "description": "Contact user@example.com\\nfor help",
          "details": {
            "value": [{
              "type": "invalid",
              "description": "Contact second@example.com",
              "submitted_value": "private user text"
            }]
          },
          "requester": {"email": "private@example.com"}
        }
        """
        ZendeskURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }

        let receivedError = submitRequestAndWait()

        guard case let .serverError(statusCode, bodyExcerpt) = receivedError else {
            XCTFail("Expected a server error")
            return
        }
        XCTAssertEqual(statusCode, 422)
        XCTAssertEqual(
            bodyExcerpt,
            #"error: RecordInvalid, description: Contact <redacted-email> for help, details: {"value":[{"description":"Contact <redacted-email>","type":"invalid"}]}"#
        )
        XCTAssertFalse(bodyExcerpt?.contains("requester") == true)
        XCTAssertFalse(bodyExcerpt?.contains("private@example.com") == true)
        XCTAssertFalse(bodyExcerpt?.contains("private user text") == true)
        XCTAssertFalse(bodyExcerpt?.contains("\n") == true)
    }

    func testServerErrorOmitsArbitraryPlainTextBody() {
        ZendeskURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            return (response, Data("private user text".utf8))
        }

        let receivedError = submitRequestAndWait()

        guard case let .serverError(_, bodyExcerpt) = receivedError else {
            XCTFail("Expected a server error")
            return
        }
        XCTAssertEqual(bodyExcerpt, "<non-JSON response omitted>")
    }

    func testOfflineErrorMapsToNoInternetConnection() {
        ZendeskURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let receivedError = submitRequestAndWait()

        guard case .noInternetConnection = receivedError else {
            XCTFail("Expected a no-internet-connection error")
            return
        }
    }

    private func submitRequestAndWait() -> ZendeskSupportService.SupportRequestError? {
        let completionExpectation = expectation(description: "Request completes")
        var receivedError: ZendeskSupportService.SupportRequestError?

        makeService()
            .submitSupportRequest(makeSupportRequest())
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    receivedError = error as? ZendeskSupportService.SupportRequestError
                }
                completionExpectation.fulfill()
            }, receiveValue: { _ in
                XCTFail("Expected the request to fail")
            })
            .store(in: &cancellables)

        wait(for: [completionExpectation], timeout: 1)
        return receivedError
    }

    private func makeService() -> ZendeskSupportService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ZendeskURLProtocol.self]
        return ZendeskSupportService(config: ZendeskTestConfig(), session: URLSession(configuration: configuration))
    }

    private func makeSupportRequest() -> ZDSupportRequest {
        ZDSupportRequest(
            subject: "Support",
            name: "Test User",
            email: "test@example.com",
            comment: "Help"
        )
    }
}

final class MessageSupportViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        ZendeskURLProtocol.requestHandler = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testWatchLogPreflightFailureDoesNotSubmitOrRetry() {
        var requestCount = 0
        ZendeskURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let completionExpectation = expectation(description: "Preflight failure is surfaced")
        let viewModel = MessageSupportViewModel(
            config: WatchLogMissingConfig(),
            requesterName: "Test User",
            requesterEmail: "test@example.com",
            comment: "My watch is not working",
            session: makeSession(),
            isUserSignedIn: false
        )

        viewModel.$completion
            .compactMap { $0 }
            .sink { completion in
                guard case let .failure(error) = completion,
                      case MessageSupportViewModel.MessageSupportFailure.watchLogMissing = error
                else {
                    XCTFail("Expected a missing Watch log failure")
                    return
                }
                completionExpectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.submitRequest()

        wait(for: [completionExpectation], timeout: 1)
        XCTAssertEqual(requestCount, 0)
        XCTAssertFalse(viewModel.isWorking)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ZendeskURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private struct ZendeskTestConfig: ZDConfig {
    let apiKey = "api-key"
    let baseURL = "https://example.com"
    let newBaseURL = "https://retry.example.com"
    let subject = "Support"
    let type = ZDType.support
}

private struct WatchLogMissingConfig: ZDConfig {
    let apiKey = "api-key"
    let baseURL = "https://example.com"
    let newBaseURL = "https://retry.example.com"
    let subject = "Support"
    let type = ZDType.support

    func customFields(forDisplay: Bool, optOut: Bool) -> AnyPublisher<[ZDCustomField], Never> {
        Just([ZDCustomField(id: 0, value: FileLog.noWearableLogsAvailable)])
            .eraseToAnyPublisher()
    }
}

private final class ZendeskURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

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
