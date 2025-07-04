import XCTest
@testable import podcasts
@testable import PocketCastsServer
@testable import PocketCastsUtils

final class DiscoverItemObservableTests: XCTestCase {

    let featureFlagMock = FeatureFlagMock()

    override func tearDown() {
        featureFlagMock.reset()
    }

    class MockServerHandler: DiscoverServerHandling {
        func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
            return [
                DiscoverCategory(id: 1, name: "Tech"),
                DiscoverCategory(id: 2, name: "News"),
                DiscoverCategory(id: 3, name: "Science")
            ]
        }
    }

    func testPopularFiltering() async {
        class Mock: MockServerHandler {
        }

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item2",
            title: "Test 2",
            source: "mockSource",
            regions: [],
            popular: [1],
            authenticated: false
        )

        let result = await observable.load()
        XCTAssertEqual(result?.prioritized.map(\.id), [1])
    }

    func testCategorySponsoredRanking() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science"),
                    DiscoverCategory(id: 4, name: "Sports"),
                    DiscoverCategory(id: 5, name: "Music"),
                    DiscoverCategory(id: 6, name: "Comedy"),
                    DiscoverCategory(id: 7, name: "History")
                ]
            }
        }

        // Set up mock visitation data - top 6 most visited
        UserDefaults.standard.set([
            "3": 10, // Science - most visited (sponsored)
            "1": 8,  // Tech - second most visited
            "6": 7,  // Comedy - third most visited
            "2": 6,  // News - fourth most visited (sponsored)
            "4": 5,  // Sports - fifth most visited
            "7": 4   // History - sixth most visited
            // Music (id: 5) has no visits, so not in top 6
        ], forKey: UserDefaults.VisitationTrackEvent.discoverCategory.key)

        featureFlagMock.set(.smartCategories, value: true)

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test Categories",
            source: "mockSource",
            regions: [],
            popular: nil,
            authenticated: false,
            sponsoredCategoryIDs: [2, 3] // Both in top 6
        )

        let result = await observable.load()

        // Expected: Only top 6 categories, with sponsored from top 6 first, then rest by visit count
        // Science (3) and News (2) are sponsored and in top 6, so they come first
        XCTAssertEqual(result?.prioritized.map(\.id), [3, 2, 1, 6, 4, 7])
        XCTAssertEqual(result?.prioritized.count, 6)
    }

    func testSponsoredCategoriesOnlyPromotedIfInTop6() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science")
                ]
            }
        }

        // Set up visitation data where sponsored category is in top visits
        UserDefaults.standard.set([
            "1": 100, // Tech - most visited (non-sponsored)
            "3": 50   // Science - second most visited (sponsored)
        ], forKey: UserDefaults.VisitationTrackEvent.discoverCategory.key)

        featureFlagMock.set(.smartCategories, value: true)

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test",
            source: "mockSource",
            regions: [],
            popular: nil,
            authenticated: false,
            sponsoredCategoryIDs: [3]
        )

        let result = await observable.load()

        // Science is sponsored AND in top 6, so it gets promoted first
        XCTAssertEqual(result?.prioritized.map(\.id), [3, 1, 2])
    }

    func testMultipleSponsoredCategoriesInTop6() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science"),
                    DiscoverCategory(id: 4, name: "Sports")
                ]
            }
        }

        // Multiple sponsored categories with different visit patterns
        UserDefaults.standard.set([
            "2": 20, // News - most visited (sponsored)
            "1": 15, // Tech - second most visited (sponsored)
            "3": 10, // Science - third most visited
            "4": 5   // Sports - fourth most visited (sponsored)
        ], forKey: UserDefaults.VisitationTrackEvent.discoverCategory.key)

        featureFlagMock.set(.smartCategories, value: true)

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test",
            source: "mockSource",
            regions: [],
            popular: nil,
            authenticated: false,
            sponsoredCategoryIDs: [1, 2, 4] // All are in top 6
        )

        let result = await observable.load()

        // Expected: sponsored categories from top 6 first (by visit count), then non-sponsored
        XCTAssertEqual(result?.prioritized.map(\.id), [2, 1, 4, 3])
    }

    func testNoSponsoredCategories() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science")
                ]
            }
        }

        UserDefaults.standard.set([
            "3": 15,
            "1": 10
        ], forKey: UserDefaults.VisitationTrackEvent.discoverCategory.key)

        featureFlagMock.set(.smartCategories, value: true)

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test",
            source: "mockSource",
            regions: [],
            popular: nil,
            authenticated: false,
            sponsoredCategoryIDs: nil
        )

        let result = await observable.load()

        // Expected: visited categories by visit count, then unvisited in original order
        XCTAssertEqual(result?.prioritized.map(\.id), [3, 1, 2])
    }

    func testSponsoredCategoriesNotInTop6NotPromoted() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science"),
                    DiscoverCategory(id: 4, name: "Sports"),
                    DiscoverCategory(id: 5, name: "Music"),
                    DiscoverCategory(id: 6, name: "Comedy"),
                    DiscoverCategory(id: 7, name: "History"),
                    DiscoverCategory(id: 8, name: "Religion")
                ]
            }
        }

        // Set up visitation data where sponsored category is NOT in top 6
        UserDefaults.standard.set([
            "1": 100, // Tech - most visited
            "3": 90,  // Science - second most visited
            "4": 80,  // Sports - third most visited
            "5": 70,  // Music - fourth most visited
            "6": 60,  // Comedy - fifth most visited
            "7": 50   // History - sixth most visited
            // Religion (id: 8, sponsored) and News (id: 2, sponsored) have no visits
        ], forKey: UserDefaults.VisitationTrackEvent.discoverCategory.key)

        featureFlagMock.set(.smartCategories, value: true)

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test",
            source: "mockSource",
            regions: [],
            popular: nil,
            authenticated: false,
            sponsoredCategoryIDs: [2, 8] // Neither in top 6
        )

        let result = await observable.load()

        // Expected: Only top 6 categories by visit count, no sponsored promotion since none are in top 6
        XCTAssertEqual(result?.prioritized.map(\.id), [1, 3, 4, 5, 6, 7])
        XCTAssertEqual(result?.prioritized.count, 6)
    }

    func testSmartCategoriesDisabled() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science")
                ]
            }
        }

        UserDefaults.standard.set([
            "3": 15,
            "1": 10
        ], forKey: UserDefaults.VisitationTrackEvent.discoverCategory.key)

        featureFlagMock.set(.smartCategories, value: false)

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: Mock())
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test",
            source: "mockSource",
            regions: [],
            popular: nil,
            authenticated: false,
            sponsoredCategoryIDs: [3]
        )

        let result = await observable.load()

        // Should return original order when feature is disabled
        XCTAssertEqual(result?.prioritized.map(\.id), [1, 2, 3])
    }
}
