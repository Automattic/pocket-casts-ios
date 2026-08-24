import Foundation
import PocketCastsDataModel
import PocketCastsServer
import XCTest

final class NetworkDiscoveryDecodingTests: XCTestCase {

    // MARK: - lists_list

    func testDecodesListsListSample() throws {
        let collection = try decodeSampleCollection()

        XCTAssertEqual(collection.listId, "network-highlights")
        XCTAssertEqual(collection.title, "Network Highlights")
        XCTAssertEqual(collection.collectionImage, "https://static.pocketcasts.com/discover/images/network-highlights.png")

        let list = try XCTUnwrap(collection.lists.first)
        XCTAssertEqual(list.uuid, "e5e1a0f0-1b3d-4f8e-9c1f-3a1d5b0c9f11")
        XCTAssertEqual(list.title, "News")
        XCTAssertEqual(list.type, "podcast_list")
        XCTAssertEqual(list.summaryStyle, "small_list")
        XCTAssertEqual(list.expandedStyle, "plain_list")
        XCTAssertEqual(list.source, "https://lists.pocketcasts.com/network-news.json")
        XCTAssertEqual(list.collectionImage, "https://static.pocketcasts.com/discover/images/network-news.png")
        XCTAssertEqual(list.itemCount, 12)
        XCTAssertEqual(list.description, "The stories shaping the day.")
        XCTAssertEqual(list.urlPath, "/lists/network-news")
    }

    func testDropsListsThatArentPodcastLists() throws {
        let collection = try decodeSampleCollection()

        XCTAssertEqual(collection.lists.count, 2)
        XCTAssertEqual(collection.lists.map(\.title), ["News", "Culture"])
    }

    func testDecodesListWithoutCollectionImage() throws {
        let collection = try decodeSampleCollection()

        let list = try XCTUnwrap(collection.lists.last)
        XCTAssertEqual(list.title, "Culture")
        XCTAssertNil(list.collectionImage)
    }

    func testDecodesEmptyLists() throws {
        let collection = try decodeCollection(from: #"{"list_id": "network-highlights", "lists": []}"#)

        XCTAssertTrue(collection.lists.isEmpty)
    }

    func testDecodesCollectionWithoutLists() throws {
        let collection = try decodeCollection(from: #"{"list_id": "a-list", "title": "A list", "podcasts": []}"#)

        XCTAssertEqual(collection.title, "A list")
        XCTAssertTrue(collection.lists.isEmpty)
    }

    func testDecodesMalformedListEntries() throws {
        let collection = try decodeCollection(from: #"{"list_id": "network-highlights", "lists": ["nope", 4, {"title": "No type"}]}"#)

        XCTAssertTrue(collection.lists.isEmpty)
    }

    // MARK: - network_list

    func testDecodesNetworkList() throws {
        let networkList = try XCTUnwrap(PodcastNetworkList(json: [
            "list_id": "network-news",
            "source": "https://lists.pocketcasts.com/network-news.json"
        ]))

        XCTAssertEqual(networkList.listId, "network-news")
        XCTAssertEqual(networkList.source, "https://lists.pocketcasts.com/network-news.json")
    }

    func testDerivesNetworkListSourceFromListId() throws {
        let networkList = try XCTUnwrap(PodcastNetworkList(json: ["list_id": "network-news"]))

        XCTAssertEqual(networkList.source, "\(ServerConstants.Urls.lists())network-news.json")
    }

    func testDecodesAbsentNetworkList() {
        XCTAssertNil(PodcastNetworkList(json: nil))
        XCTAssertNil(PodcastNetworkList(json: [:]))
        XCTAssertNil(PodcastNetworkList(json: ["list_id": ""]))
    }

    // MARK: - Helpers

    private func decodeSampleCollection() throws -> PodcastCollection {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "lists_list", withExtension: "json"))

        return try JSONDecoder().decode(PodcastCollection.self, from: try Data(contentsOf: url))
    }

    private func decodeCollection(from json: String) throws -> PodcastCollection {
        try JSONDecoder().decode(PodcastCollection.self, from: try XCTUnwrap(json.data(using: .utf8)))
    }
}
