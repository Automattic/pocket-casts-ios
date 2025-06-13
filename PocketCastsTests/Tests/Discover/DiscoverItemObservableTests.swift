import XCTest
@testable import podcasts
@testable import PocketCastsServer

final class DiscoverItemObservableTests: XCTestCase {

    class MockServerHandler: DiscoverServerHandling {
        func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
            return [
                DiscoverCategory(id: 1, name: "Tech"),
                DiscoverCategory(id: 2, name: "News"),
                DiscoverCategory(id: 3, name: "Science")
            ]
        }

        func discoverRecommendedCategories(source: String, authenticated: Bool?) async -> [Int]? {
            return [2, 3]
        }
    }

    func testRecommendedFiltering_appliesCorrectly() async {
        // Given
        let mockHandler = MockServerHandler()
        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: mockHandler)
        observable.item = DiscoverItem(
            id: "item1",
            title: "Test",
            type: "categories",
            source: "mockSource",
            regions: [],
            popular: [1, 2],
            authenticated: true,
            recommendations: DiscoverSource(source: "recSource", authenticated: true)
        )

        // When
        let result = await observable.load()

        // Then
        XCTAssertEqual(result?.categories.count, 3)
        XCTAssertEqual(result?.prioritized.map(\.id), [2, 3])
    }

    func testPopularFiltering_appliesWhenNoRecommendations() async {
        class NoRecMock: MockServerHandler {
            override func discoverRecommendedCategories(source: String, authenticated: Bool?) async -> [Int]? {
                return nil
            }
        }

        let observable = CategoriesSelectorViewController.DiscoverItemObservable(serverHandler: NoRecMock())
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
}
