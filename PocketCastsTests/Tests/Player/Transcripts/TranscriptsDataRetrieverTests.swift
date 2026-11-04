import XCTest
@testable import podcasts

final class TranscriptsDataRetrieverTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testLoadTranscriptThrowsForHTTPErrorResponse() async {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, Data("<Error><Code>AccessDenied</Code></Error>".utf8))
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
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
