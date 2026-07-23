import Combine
import Foundation
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
        let body = String(repeating: "a", count: 255) + "é"
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
        XCTAssertEqual(bodyExcerpt, body)
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

private struct ZendeskTestConfig: ZDConfig {
    let apiKey = "api-key"
    let baseURL = "https://example.com"
    let newBaseURL = "https://retry.example.com"
    let subject = "Support"
    let type = ZDType.support
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
