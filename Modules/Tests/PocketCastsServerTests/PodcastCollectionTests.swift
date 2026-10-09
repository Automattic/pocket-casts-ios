import Foundation
import PocketCastsServer
import XCTest

final class PodcastCollectionTests: XCTestCase {
    func testWebLinkTitleWhenTitleAndUrlArePresent() throws {
        let collection = try decodeCollection(from: #"{"web_title": "More from Relay", "web_url": "https://relay.fm/"}"#)

        XCTAssertEqual(collection.webLinkTitle, "More from Relay")
    }

    func testNoWebLinkTitleWhenBothAreEmpty() throws {
        let collection = try decodeCollection(from: #"{"web_title": "", "web_url": ""}"#)

        XCTAssertNil(collection.webLinkTitle)
    }

    func testNoWebLinkTitleWhenTitleIsEmpty() throws {
        let collection = try decodeCollection(from: #"{"web_title": "", "web_url": "https://relay.fm/"}"#)

        XCTAssertNil(collection.webLinkTitle)
    }

    func testNoWebLinkTitleWhenUrlIsEmpty() throws {
        let collection = try decodeCollection(from: #"{"web_title": "More from Relay", "web_url": ""}"#)

        XCTAssertNil(collection.webLinkTitle)
    }

    func testNoWebLinkTitleWhenBothAreMissing() throws {
        let collection = try decodeCollection(from: "{}")

        XCTAssertNil(collection.webLinkTitle)
    }

    private func decodeCollection(from json: String) throws -> PodcastCollection {
        try JSONDecoder().decode(PodcastCollection.self, from: try XCTUnwrap(json.data(using: .utf8)))
    }
}
