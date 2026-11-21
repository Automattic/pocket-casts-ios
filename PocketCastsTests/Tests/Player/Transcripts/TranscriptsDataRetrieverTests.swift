import XCTest
@testable import podcasts

final class TranscriptsDataRetrieverTests: XCTestCase {

    func testLoadTranscriptThrowsForHTTPErrorResponse() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ForbiddenURLProtocol.self]
        let retriever = TranscriptsDataRetriever(urlSession: URLSession(configuration: configuration))
        let url = URL(string: "https://example.com/\(UUID().uuidString).vtt")!

        do {
            let transcript = try await retriever.loadTranscript(url: url)
            XCTFail("Expected an error, got \(String(describing: transcript))")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }
}

private final class ForbiddenURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("<Error><Code>AccessDenied</Code></Error>".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
