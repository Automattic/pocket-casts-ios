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
}
