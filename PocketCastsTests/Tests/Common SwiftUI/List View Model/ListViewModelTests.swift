@testable import podcasts
import XCTest

@MainActor
final class ListViewModelTests: XCTestCase {
    private var testItems: [TestableModel] = [
        .init(title: "one"),
        .init(title: "two"),
        .init(title: "three")
    ]

    func testModelInitSetsCorrectly() {
        let viewModel = ListViewModel(items: testItems)

        XCTAssertEqual(testItems, viewModel.items)
        XCTAssertEqual(testItems.count, viewModel.numberOfItems)
    }

    func testIsLastReturnsTrue() {
        let viewModel = ListViewModel(items: testItems)

        XCTAssertTrue(viewModel.isLast(item: testItems.last!))
    }

    func testCountUpdatesOnItemsChange() {
        let viewModel = ListViewModel<TestableModel>()
        XCTAssertEqual(viewModel.numberOfItems, 0)

        viewModel.items.append(.init(title: "one"))

        XCTAssertEqual(viewModel.numberOfItems, 1)
    }

    // MARK: - Test Model
    private struct TestableModel: Hashable {
        let title: String
    }
}
