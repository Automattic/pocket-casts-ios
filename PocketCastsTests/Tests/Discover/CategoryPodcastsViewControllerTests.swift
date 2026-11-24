import Combine
import PocketCastsDataModel
import XCTest
@testable import podcasts
@testable import PocketCastsServer

final class CategoryPodcastsViewControllerTests: XCTestCase {

    // MARK: - Bug Fix: PCIOS-561
    // Top 5 podcasts were being repeated on Category pages.
    // The fix uses summaryItemCount from DiscoverItem to skip podcasts already shown in the carousel.

    func testCategoryPodcastsViewControllerInitializesWithZeroSkipCount() {
        // Given/When: A CategoryPodcastsViewController initialized with default skipCount
        let viewController = CategoryPodcastsViewController(region: "us")

        // Then: skipCount should be 0 by default
        XCTAssertEqual(
            viewController.skipCount,
            0,
            "CategoryPodcastsViewController should initialize with skipCount of 0"
        )
    }

    func testCategoryPodcastsViewControllerCanBeInitializedWithCustomSkipCount() {
        // Given/When: A CategoryPodcastsViewController initialized with a custom skipCount
        let viewController = CategoryPodcastsViewController(region: "us", skipCount: 5)

        // Then: skipCount should match the provided value
        XCTAssertEqual(
            viewController.skipCount,
            5,
            "CategoryPodcastsViewController should use the provided skipCount"
        )
    }

    func testCategoryPodcastsViewControllerUpdatesSkipCountFromItem() {
        // Given: A CategoryPodcastsViewController with default skipCount
        let viewController = CategoryPodcastsViewController(region: "us")
        XCTAssertEqual(viewController.skipCount, 0, "Initial skipCount should be 0")

        // And: A DiscoverItem with summaryItemCount indicating podcasts to skip
        let item = DiscoverItem(
            id: "category-1",
            title: "Technology",
            type: "category_podcast_list",
            summaryItemCount: 5, // Skip first 5 podcasts (already shown in carousel)
            source: "https://example.com/tech",
            regions: ["us"],
            categoryID: 1
        )

        // When: updateSkipCount is called with the item
        viewController.updateSkipCount(from: item)

        // Then: skipCount should be updated from item.summaryItemCount
        XCTAssertEqual(
            viewController.skipCount,
            5,
            "CategoryPodcastsViewController should update skipCount from item.summaryItemCount"
        )
    }

    func testCategoryPodcastsViewControllerKeepsZeroSkipCountWhenItemHasNoSummaryItemCount() {
        // Given: A CategoryPodcastsViewController with default skipCount
        let viewController = CategoryPodcastsViewController(region: "us")

        // And: A DiscoverItem WITHOUT summaryItemCount
        let item = DiscoverItem(
            id: "category-1",
            title: "Technology",
            type: "category_podcast_list",
            source: "https://example.com/tech",
            regions: ["us"],
            categoryID: 1
        )

        // When: updateSkipCount is called with the item
        viewController.updateSkipCount(from: item)

        // Then: skipCount should remain 0
        XCTAssertEqual(
            viewController.skipCount,
            0,
            "CategoryPodcastsViewController should keep skipCount at 0 when item has no summaryItemCount"
        )
    }

    // MARK: - Bug Fix: PCIOS-1368

    func testFailedLoadStopsSpinnerAndShowsNoNetworkView() {
        var category = DiscoverCategory(id: 1, name: "Fiction")
        category.source = "https://example.com/fiction"
        let viewController = CategoryPodcastsViewController(category: category, region: "us")
        let serverHandler = FailingDiscoverServerHandler()
        let delegate = StubDiscoverDelegate()
        viewController.serverHandler = serverHandler
        viewController.registerDiscoverDelegate(delegate)
        viewController.loadViewIfNeeded()

        let item = DiscoverItem(id: "category-1", title: "Fiction", type: "category_podcast_list", source: category.source, regions: ["us"], categoryID: 1)
        viewController.populateFrom(item: item, region: "us", category: category)

        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)

        XCTAssertEqual(serverHandler.categoryDetailsRequestCount, 1)
        XCTAssertFalse(viewController.loadingIndicator.isAnimating)
        XCTAssertFalse(viewController.noNetworkView.isHidden)
    }
}

private final class FailingDiscoverServerHandler: DiscoverServerHandling {
    private(set) var categoryDetailsRequestCount = 0

    func discoverPodcastList(source: String, authenticated: Bool?, completion: @escaping (PodcastList?) -> Void) {
        completion(nil)
    }

    func discoverPodcastCollection(source: String, authenticated: Bool?, completion: @escaping (PodcastCollection?) -> Void) {
        completion(nil)
    }

    func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
        []
    }

    func discoverCategories(source: String, authenticated: Bool?, completion: @escaping ([DiscoverCategory]?) -> Void) {
        completion(nil)
    }

    func discoverCategoryDetails(source: String, authenticated: Bool?, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        categoryDetailsRequestCount += 1
        completion(nil)
    }

    func discoverItem<T>(_ source: String?, authenticated: Bool, type: T.Type) -> AnyPublisher<T, Error> where T: Decodable {
        Empty().eraseToAnyPublisher()
    }
}

private final class StubDiscoverDelegate: DiscoverDelegate {
    func show(podcastInfo: PodcastInfo, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {}
    func show(discoverPodcast: DiscoverPodcast, placeholderImage: UIImage?, isFeatured: Bool, listUuid: String?) {}
    func show(podcast: Podcast) {}
    func showExpanded(item: DiscoverItem, category: DiscoverCategory?) {}
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?) {}
    func showExpanded(item: DiscoverItem, podcasts: [DiscoverPodcast], podcastCollection: PodcastCollection?, datetime: String?) {}
    func showExpanded(item: DiscoverItem, episodes: [DiscoverEpisode], podcastCollection: PodcastCollection?) {}
    func replaceRegionCode(string: String?) -> String? { string }
    func replaceRegionName(string: String) -> String { string }
    func isSubscribed(podcast: DiscoverPodcast) -> Bool { false }
    func subscribe(podcast: DiscoverPodcast) {}
    func navController() -> UINavigationController? { nil }
    func show(discoverEpisode: DiscoverEpisode, podcast: Podcast) {}
    func failedToLoadEpisode() {}
    func navigateTo(category: String) {}
    func navigateTo(listID: String) {}
}
