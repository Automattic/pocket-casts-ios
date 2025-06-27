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
                    DiscoverCategory(id: 5, name: "Music")
                ]
            }
        }

        // Set up mock visitation data
        UserDefaults.standard.set([
            "3": 10, // Science - most visited
            "1": 5,  // Tech - second most visited
            "4": 2   // Sports - least visited
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
            sponsoredCategoryIDs: [2, 3]
        )

        let result = await observable.load()

        // Expected order: Science (sponsored + most visited), News (sponsored + unvisited), Tech (non-sponsored + visited), Sports (non-sponsored + visited), Music (non-sponsored + unvisited)
        XCTAssertEqual(result?.prioritized.map(\.id), [3, 2, 1, 4, 5])
        XCTAssertEqual(result?.categories.count, 5)
    }

    func testSponsoredCategoriesAlwaysFirst() async {
        class Mock: MockServerHandler {
            override func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
                return [
                    DiscoverCategory(id: 1, name: "Tech"),
                    DiscoverCategory(id: 2, name: "News"),
                    DiscoverCategory(id: 3, name: "Science")
                ]
            }
        }

        // Set up visitation data where non-sponsored has more visits
        UserDefaults.standard.set([
            "1": 100, // Tech - most visited (non-sponsored)
            "3": 5    // Science - less visited (sponsored)
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

        // Sponsored should come first despite having fewer visits
        XCTAssertEqual(result?.prioritized.map(\.id), [3, 1, 2])
    }

    func testVisitedCategoriesWithinSponsoredGroup() async {
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
            "2": 20, // News - more visited
            "1": 10  // Tech - less visited
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
            sponsoredCategoryIDs: [1, 2, 4] // 1 and 2 visited, 4 unvisited
        )

        let result = await observable.load()

        // Expected: visited sponsored (by visit count), unvisited sponsored, then non-sponsored
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
