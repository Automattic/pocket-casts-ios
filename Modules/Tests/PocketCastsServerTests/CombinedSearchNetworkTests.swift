import Foundation
@testable import PocketCastsServer
import XCTest

final class CombinedSearchNetworkTests: XCTestCase {
    /// A payload shaped like the one `search/combined` returns for a term matching a network.
    private let json = """
    {
      "results": [
        {
          "uuid": "c59b45b0-0bc4-012e-fb02-00163e1b201c",
          "title": "Planet Money",
          "author": "NPR",
          "explicit": null,
          "is_video": false,
          "type": "podcast"
        },
        {
          "uuid": "c73d120f-c174-4324-b0a3-18f9b239a59d",
          "title": "WNYC",
          "subtitle": "",
          "short_description": "New York's flagship public radio station",
          "collection_image": "https://static.pocketcasts.net/share/images/c73d120f-author.png",
          "web_url": "https://www.wnyc.org/shows/",
          "web_title": "More from WNYC",
          "url_path": "",
          "podcast_count": 11,
          "match_reason": "term",
          "matched_podcast_count": 10,
          "type": "network"
        },
        {
          "uuid": "3f7b2c10-0000-0000-0000-000000000000",
          "title": "Something new",
          "type": "future_type"
        }
      ]
    }
    """

    private func results() throws -> [CombinedSearchResultType] {
        let envelope = try CombinedSearchTask.decoder.decode(CombinedSearchEnvelope.self, from: Data(json.utf8))
        return envelope.results.compactMap { $0.resolvedResultType }
    }

    func testDecodesNetworkAlongsideOtherResults() throws {
        let results = try results()

        XCTAssertEqual(results.count, 2, "The unsupported type is dropped rather than failing the whole response")

        guard case .podcast(let podcast) = results[0] else {
            XCTFail("Expected the first result to stay a podcast, got \(results[0])")
            return
        }
        XCTAssertEqual(podcast.title, "Planet Money")

        guard case .network(let network) = results[1] else {
            XCTFail("Expected the second result to be a network, got \(results[1])")
            return
        }
        XCTAssertEqual(network.uuid, "c73d120f-c174-4324-b0a3-18f9b239a59d")
        XCTAssertEqual(network.title, "WNYC")
        XCTAssertEqual(network.description, "New York's flagship public radio station")
        XCTAssertEqual(network.collectionImage, "https://static.pocketcasts.net/share/images/c73d120f-author.png")
        XCTAssertEqual(network.podcastCount, 11)
    }

    /// Search returns no source of its own, so opening a network relies on this being the list's URL.
    func testNetworkSourceIsItsList() throws {
        let results = try results()

        guard case .network(let network) = results[1] else {
            XCTFail("Expected the second result to be a network, got \(results[1])")
            return
        }
        XCTAssertEqual(network.source, "\(ServerConstants.Urls.lists())c73d120f-c174-4324-b0a3-18f9b239a59d.json")
    }

    func testNonNetworkResultDoesNotBecomeANetwork() throws {
        let podcast = CombinedSearchResult(
            type: "podcast",
            uuid: "c59b45b0-0bc4-012e-fb02-00163e1b201c",
            title: "Planet Money",
            publishedDate: nil,
            duration: nil,
            podcastUuid: nil,
            podcastTitle: nil,
            author: "NPR",
            explicit: nil,
            isVideo: nil,
            hasVideo: nil,
            videoUrl: nil,
            shortDescription: nil,
            collectionImage: nil,
            podcastCount: nil
        )

        XCTAssertNil(NetworkSearchResult(from: podcast))
    }
}
