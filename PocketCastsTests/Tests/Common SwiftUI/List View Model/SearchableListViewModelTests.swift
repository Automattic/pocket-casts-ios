@testable import podcasts
import XCTest

@MainActor
final class SearchableListViewModelTests: XCTestCase {
    private var testItems: [TestableModel] = [
        .init(title: "one"),
        .init(title: "two"),
        .init(title: "three"),
        .init(title: "one two three")
    ]

    private var viewModel: SearchableListViewModel<TestableModel> = .init()

    override func setUp() {
        viewModel = SearchableListViewModel(items: testItems)
    }

    func testSearchingReturnsCorrectly() {
        viewModel.search(with: "ONE")

        XCTAssertEqual(viewModel.numberOfFilteredItems, 2)
        XCTAssertEqual(viewModel.filteredItems, [testItems[0], testItems[3]])
    }

    func testSearchIgnoresPaddedSpaces() {
        viewModel.search(with: "       one        ")

        XCTAssertEqual(viewModel.numberOfFilteredItems, 2)
        XCTAssertEqual(viewModel.filteredItems, [testItems[0], testItems[3]])
    }

    func testSearchResetsOnEmpty() {
        viewModel.search(with: "ONE")

        XCTAssertTrue(viewModel.isSearching)

        viewModel.search(with: "")

        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchResultsAreUpdatedWhenItemsChange() {
        viewModel.search(with: "three")
        viewModel.searchText = "three"

        XCTAssertEqual(viewModel.numberOfFilteredItems, 2)

        viewModel.items = testItems + [.init(title: "another three"), .init(title: "no")]

        XCTAssertEqual(viewModel.numberOfFilteredItems, 3)
    }

    func testStopsSearchingWhenThereAreNoItems() {
        viewModel.search(with: "three")
        XCTAssertEqual(viewModel.numberOfFilteredItems, 2)

        viewModel.items = []

        XCTAssertEqual(viewModel.numberOfFilteredItems, 0)
        XCTAssertFalse(viewModel.isSearching)
    }

    // MARK: - Test Model
    private struct TestableModel: SearchableDataModel {
        let title: String

        var searchField: String { title }
    }
}
