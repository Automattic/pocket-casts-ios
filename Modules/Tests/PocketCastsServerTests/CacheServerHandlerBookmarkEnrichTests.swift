@testable import PocketCastsServer
import XCTest

final class CacheServerHandlerBookmarkEnrichTests: XCTestCase {
    private func makeHandler(mockHandler: @escaping MockRequestHandler.Handler) -> CacheServerHandler {
        CacheServerHandler(tokenHelper: TokenHelper(urlConnection: URLConnection(mockHandler: mockHandler)))
    }

    func testEnrichBookmarkSendsExpectedRequest() async throws {
        var capturedRequest: URLRequest?
        let handler = makeHandler { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            let data = try JSONSerialization.data(withJSONObject: ["title": "A title", "summary": "A summary"])
            return (data, response)
        }

        let result = try await handler.enrichBookmark(transcriptSnippet: "some transcript text")

        XCTAssertEqual(capturedRequest?.url?.absoluteString, ServerConstants.Urls.cache() + "mobile/bookmark/enrich")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")

        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: String])
        XCTAssertEqual(json, ["transcript_snippet": "some transcript text"])

        XCTAssertEqual(result.title, "A title")
        XCTAssertEqual(result.summary, "A summary")
        XCTAssertNil(result.error)
    }

    func testEnrichBookmarkParsesErrorField() async throws {
        let handler = makeHandler { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            let data = try JSONSerialization.data(withJSONObject: ["error": "something went wrong"])
            return (data, response)
        }

        let result = try await handler.enrichBookmark(transcriptSnippet: "some transcript text")

        XCTAssertNil(result.title)
        XCTAssertNil(result.summary)
        XCTAssertEqual(result.error, "something went wrong")
    }

    func testEnrichBookmarkThrowsOnServerError() async {
        let handler = makeHandler { request in
            (nil, HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil))
        }

        do {
            _ = try await handler.enrichBookmark(transcriptSnippet: "some transcript text")
            XCTFail("Expected enrichBookmark to throw")
        } catch {}
    }
}
