import XCTest
@testable import podcasts
import PocketCastsServer


final class FeaturedSummaryViewControllerTests: XCTestCase {
    @MainActor func testPopulateItem() async throws {
        let vc = FeaturedSummaryViewController(nibName: nil, bundle: nil)

        let jsonData = """
        {
          "id": "featured",
          "title": "Featured",
          "type": "podcast_list",
          "summary_style": "carousel",
          "expanded_style": "plain_list",
          "source": "https://lists.pocketcasts.com/featured.json",
          "category_id": null,
          "sponsored_podcasts": [
            {
              "position": 0,
              "source": "https://lists.pocketcasts.com/972fda60-5a69-4713-b925-bf89f69c5fda.json"
            },
            {
              "position": 2,
              "source": "https://lists.pocketcasts.com/478726f8-7b18-441b-bc0a-c49939697c38.json"
            }
          ],
          "regions": [
            "au",
            "at",
            "be",
            "br",
            "ca",
            "cn",
            "dk",
            "fi",
            "fr",
            "de",
            "ie",
            "in",
            "it",
            "jp",
            "mx",
            "nl",
            "no",
            "nz",
            "pl",
            "pt",
            "ru",
            "kr",
            "es",
            "se",
            "ch",
            "gb",
            "us",
            "za",
            "sg",
            "ph",
            "hk",
            "sa",
            "tr",
            "il",
            "cz",
            "tw",
            "ua",
            "global"
          ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let featuredItem = try decoder.decode(DiscoverItem.self, from: jsonData)

        vc.populateFrom(item: featuredItem, region: "global", category: nil)

        await self.waitForCondition(timeout: 5) {
            vc.podcasts.isEmpty == false
        }

        for podcast in featuredItem.sponsoredPodcasts ?? [] {
            let index = try XCTUnwrap(podcast.position)
            let source = try XCTUnwrap(podcast.source)
            let loadedPodcast = await DiscoverServerHandler.shared.discoverPodcastCollection(source: source)
            XCTAssertEqual(vc.podcasts[index].uuid, loadedPodcast?.podcasts?.first?.uuid)
        }

        vc.populateFrom(item: featuredItem, region: "global", category: nil)

        self.eventually(timeout: 5) {
            vc.podcasts.isEmpty == false
        }

        for podcast in featuredItem.sponsoredPodcasts ?? [] {
            let index = try XCTUnwrap(podcast.position)
            let source = try XCTUnwrap(podcast.source)
            let loadedPodcast = await DiscoverServerHandler.shared.discoverPodcastCollection(source: source)
            XCTAssertEqual(vc.podcasts[index].uuid, loadedPodcast?.podcasts?.first?.uuid)
        }
    }
}
