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
}
