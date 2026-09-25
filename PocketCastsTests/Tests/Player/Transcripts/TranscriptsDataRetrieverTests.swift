import XCTest
@testable import podcasts

final class TranscriptsDataRetrieverTests: XCTestCase {

    override func tearDown() {
        TranscriptStubURLProtocol.responses = [:]
        super.tearDown()
    }

    func testLoadTranscriptThrowsForHTTPErrorResponse() async {
        let url = URL(string: "https://shownotes.pocketcasts.com/generated_transcripts/\(UUID().uuidString).vtt")!
        TranscriptStubURLProtocol.responses[url] = (403, TranscriptStubURLProtocol.accessDeniedBody)
        let retriever = TranscriptsDataRetriever(urlSession: TranscriptStubURLProtocol.makeSession())

        do {
            let transcript = try await retriever.loadTranscript(url: url)
            XCTFail("Expected an error, got \(String(describing: transcript))")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
        }
    }

    func testLoadTranscriptReturnsBodyForSuccessfulResponse() async throws {
        let url = URL(string: "https://example.com/\(UUID().uuidString).txt")!
        TranscriptStubURLProtocol.responses[url] = (200, "Hello")
        let retriever = TranscriptsDataRetriever(urlSession: TranscriptStubURLProtocol.makeSession())

        let transcript = try await retriever.loadTranscript(url: url)

        XCTAssertEqual(transcript, "Hello")
    }
}

final class TranscriptStubURLProtocol: URLProtocol {
    static var responses: [URL: (statusCode: Int, body: String)] = [:]

    static let accessDeniedBody = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>
    """

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TranscriptStubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let stub = Self.responses[url],
              let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
