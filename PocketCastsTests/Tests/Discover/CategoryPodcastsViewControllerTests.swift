import XCTest
@testable import podcasts
@testable import PocketCastsServer

final class CategoryPodcastsViewControllerTests: XCTestCase {

    // MARK: - Bug Reproduction: PCIOS-561
    // Top 5 podcasts are being repeated on Category pages
    //
    // When viewing a category page, the "Most Popular" carousel shows the top 5 podcasts.
    // The list below should start at #6, but currently shows all podcasts including the top 5.
    //
    // Root cause: CategoryPodcastsViewController doesn't use summaryItemCount from the
    // DiscoverItem to skip podcasts already shown in the carousel.

    func testCategoryListItemShouldIncludeSummaryItemCountToSkipCarouselPodcasts() {
        // Given: A category with a "Most Popular" section showing 5 items
        var category = DiscoverCategory(id: 1, name: "Technology")
        category.source = "https://example.com/tech"
        let popularItemsCount = 5

        // When: Creating a category list item for the full podcast list
        // The item should specify how many podcasts to skip (those already in the carousel)
        let categoryListItem = DiscoverItem(
            id: "category-\(category.id ?? 0)",
            title: category.name,
            type: "category_podcast_list",
            summaryItemCount: popularItemsCount, // This is what the fix should add
            source: category.source,
            regions: ["us"],
            categoryID: category.id
        )

        // Then: The item should have summaryItemCount set to skip the carousel podcasts
        XCTAssertEqual(
            categoryListItem.summaryItemCount,
            popularItemsCount,
            "Category list item should have summaryItemCount to indicate how many podcasts to skip"
        )
    }

    func testCategoryPodcastsViewControllerInitializesWithZeroSkipCount() {
        // Given/When: A CategoryPodcastsViewController initialized with default skipCount
        let viewController = CategoryPodcastsViewController(region: "us")

        // Then: skipCount should be 0 by default
        XCTAssertEqual(
            viewController.currentSkipCount,
            0,
            "CategoryPodcastsViewController should initialize with skipCount of 0"
        )
    }

    func testCategoryPodcastsViewControllerCanBeInitializedWithCustomSkipCount() {
        // Given/When: A CategoryPodcastsViewController initialized with a custom skipCount
        let viewController = CategoryPodcastsViewController(region: "us", skipCount: 5)

        // Then: skipCount should match the provided value
        XCTAssertEqual(
            viewController.currentSkipCount,
            5,
            "CategoryPodcastsViewController should use the provided skipCount"
        )
    }

    func testCategoryPodcastsViewControllerUpdatesSkipCountFromItem() {
        // Given: A CategoryPodcastsViewController with default skipCount
        let viewController = CategoryPodcastsViewController(region: "us")
        XCTAssertEqual(viewController.currentSkipCount, 0, "Initial skipCount should be 0")

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

        var category = DiscoverCategory(id: 1, name: "Technology")
        category.source = "https://example.com/tech"

        // When: updateSkipCount is called with the item
        // (This method will be added as part of the fix)
        viewController.updateSkipCount(from: item)

        // Then: skipCount should be updated from item.summaryItemCount
        // This test will FAIL until the fix is implemented
        XCTAssertEqual(
            viewController.currentSkipCount,
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
            viewController.currentSkipCount,
            0,
            "CategoryPodcastsViewController should keep skipCount at 0 when item has no summaryItemCount"
        )
    }
}
