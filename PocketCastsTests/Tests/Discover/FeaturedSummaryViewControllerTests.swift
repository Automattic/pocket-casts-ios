import Combine
import XCTest
@testable import podcasts
@testable import PocketCastsServer

final class FeaturedSummaryViewControllerTests: XCTestCase {
    func testShowsTheFeaturedPodcastsWhenASponsoredListFailsToLoad() {
        let viewController = FeaturedSummaryViewController()
        viewController.serverHandler = FeaturedServerHandler(featuredPodcastCount: 3)
        viewController.loadViewIfNeeded()

        let item = DiscoverItem(
            title: "Featured",
            type: "podcast_list",
            summaryStyle: "carousel",
            source: FeaturedServerHandler.featuredSource,
            sponsoredPodcasts: [CarouselSponsoredPodcast(position: 0, source: "https://example.com/sponsored.json")],
            regions: ["us"]
        )
        viewController.populateFrom(item: item, region: "us", category: nil)

        let loaded = expectation(for: NSPredicate { _, _ in
            viewController.featuredCollectionView.numberOfItems(inSection: 0) == 3
        }, evaluatedWith: nil)
        wait(for: [loaded], timeout: 5)
    }
}

/// Answers the featured list and fails every other request.
private struct FeaturedServerHandler: DiscoverServerHandling {
    static let featuredSource = "https://example.com/featured.json"

    let featuredPodcastCount: Int

    func discoverPodcastList(source: String, authenticated: Bool?, completion: @escaping (PodcastList?) -> Void) {
        guard source == Self.featuredSource else {
            completion(nil)
            return
        }

        let podcasts = (0..<featuredPodcastCount).map { index in
            var podcast = DiscoverPodcast()
            podcast.uuid = "podcast-\(index)"
            podcast.title = "Podcast \(index)"
            return podcast
        }
        completion(PodcastList(podcasts: podcasts, datetime: nil))
    }

    func discoverPodcastCollection(source: String, authenticated: Bool?, completion: @escaping (PodcastCollection?) -> Void) {
        completion(nil)
    }

    func discoverCategories(source: String, authenticated: Bool?, completion: @escaping ([DiscoverCategory]?) -> Void) {
        completion(nil)
    }

    func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
        []
    }

    func discoverCategoryDetails(source: String, authenticated: Bool?, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        completion(nil)
    }

    func discoverItem<T>(_ source: String?, authenticated: Bool, type: T.Type) -> AnyPublisher<T, Error> where T: Decodable {
        Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
    }
}
