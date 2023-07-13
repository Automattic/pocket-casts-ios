@testable import podcasts
import XCTest

@MainActor
final class MultiSelectListViewModelTests: XCTestCase {
    private var viewModel: MultiSelectListViewModel<TestableModel> = .init()

    private var testItems: [TestableModel] = [
        .init(title: "one"),
        .init(title: "two"),
        .init(title: "three")
    ]

    override func setUp() {
        viewModel = MultiSelectListViewModel(items: testItems)
    }

    // MARK: - Entering / Exiting Multi Selection
    func testToggleMultiSelectionEntersCorrectly() {
        XCTAssertFalse(viewModel.isMultiSelecting)

        viewModel.toggleMultiSelection()
        XCTAssertTrue(viewModel.isMultiSelecting)
    }

    func testToggleMultiSelectionExitsCorrectly() {
        // Enter
        viewModel.toggleMultiSelection()

        // Exit
        viewModel.toggleMultiSelection()

        XCTAssertFalse(viewModel.isMultiSelecting)
    }

    func testExitingMultiSelectionResetsSelection() {
        viewModel.toggleMultiSelection()
        viewModel.select(item: testItems.first!)

        viewModel.toggleMultiSelection()
        XCTAssertTrue(viewModel.selectedItems.isEmpty)
        XCTAssertEqual(viewModel.numberOfSelectedItems, 0)
    }

    // MARK: - Selection Toggling

    func testToggleSelected() {
        // Select the last item first
        viewModel.toggleSelected(testItems.last!)
        XCTAssertTrue(viewModel.isSelected(testItems.last!))
        XCTAssertFalse(viewModel.isSelected(testItems.first!))

        // Select first and last
        viewModel.toggleSelected(testItems.first!)
        XCTAssertTrue(viewModel.isSelected(testItems.last!))
        XCTAssertTrue(viewModel.isSelected(testItems.first!))

        // Deselect the last item
        viewModel.toggleSelected(testItems.last!)

        XCTAssertFalse(viewModel.isSelected(testItems.last!))
        XCTAssertTrue(viewModel.isSelected(testItems.first!))
    }

    // MARK: - Select/Deselect All

    func testSelectAll() {
        XCTAssertFalse(viewModel.hasSelectedAll)

        viewModel.selectAll()

        XCTAssertTrue(viewModel.hasSelectedAll)
        XCTAssertEqual(viewModel.numberOfSelectedItems, testItems.count)
    }

    func testDeselectAll() {
        XCTAssertFalse(viewModel.hasSelectedAll)
        viewModel.selectAll()

        viewModel.deselectAll()

        XCTAssertFalse(viewModel.hasSelectedAll)
        XCTAssertEqual(viewModel.numberOfSelectedItems, 0)
    }

    func testToggleSelectAll() {
        XCTAssertFalse(viewModel.hasSelectedAll)

        viewModel.toggleSelectAll()
        XCTAssertTrue(viewModel.hasSelectedAll)
        XCTAssertEqual(viewModel.numberOfSelectedItems, testItems.count)


        viewModel.toggleSelectAll()
        XCTAssertFalse(viewModel.hasSelectedAll)
        XCTAssertEqual(viewModel.numberOfSelectedItems, 0)
    }

    // MARK: - Select All Before

    func testSelectAllBefore() {
        let item = testItems[1]
        viewModel.selectAllBefore(item)

        XCTAssertTrue(viewModel.isSelected(testItems[0]))
        XCTAssertTrue(viewModel.isSelected(testItems[1]))
        XCTAssertFalse(viewModel.isSelected(testItems[2]))
    }

    func testSelectAllBeforeDoesNothingIfMissing() {
        let item = testItems[1]
        viewModel.items.remove(at: 1)
        viewModel.selectAllBefore(item)

        XCTAssertFalse(viewModel.isSelected(testItems[0]))
        XCTAssertFalse(viewModel.isSelected(testItems[1]))
    }

    // MARK: - Select All After

    func testSelectAllAfter() {
        let item = testItems[1]
        viewModel.selectAllAfter(item)

        XCTAssertFalse(viewModel.isSelected(testItems[0]))
        XCTAssertTrue(viewModel.isSelected(testItems[1]))
        XCTAssertTrue(viewModel.isSelected(testItems[2]))
    }

    func testSelectAllAfterDoesNothingIfMissing() {
        let item = testItems[1]
        viewModel.items.remove(at: 1)
        viewModel.selectAllAfter(item)

        XCTAssertFalse(viewModel.isSelected(testItems[0]))
        XCTAssertFalse(viewModel.isSelected(testItems[1]))
    }

    // MARK: - Long Press

    func testLongPressEntersMultiSelection() {
        let item = testItems[1]
        viewModel.longPressed(item)

        // enter multi select, and select the item that was pressed
        XCTAssertTrue(viewModel.isMultiSelecting)
        XCTAssertTrue(viewModel.isSelected(item))
    }

    func testLongPressWhenMultiSelectingShowsOptionsPicker() {
        let item = testItems[1]
        let viewModel = TestingMultiSelectViewModel(items: testItems)

        viewModel.longPressed(item)
        XCTAssertFalse(viewModel.shownOptionsPicker)
        viewModel.longPressed(item)
        XCTAssertTrue(viewModel.shownOptionsPicker)
    }

    // MARK: - Tap Selection

    func testTappedTogglesSelectionWhenMultiSelecting() {
        let item = testItems[1]
        viewModel.tapped(item: item)
        XCTAssertEqual(viewModel.numberOfSelectedItems, 0)

        viewModel.toggleMultiSelection()
        viewModel.tapped(item: item)
        XCTAssertEqual(viewModel.numberOfSelectedItems, 1)
    }

    // MARK: - Tap Selection

    func testInvalidSelectedItemsAreRemoved() {
        // Verify the removed item is deselected
        viewModel.selectAll()
        viewModel.items.remove(at: 1)

        XCTAssertEqual(viewModel.numberOfSelectedItems, 2)
    }

    func testEmptyItemsExitsMultiSelection() {
        viewModel.toggleMultiSelection()
        viewModel.selectAll()
        viewModel.items = []

        XCTAssertEqual(viewModel.isMultiSelecting, false)
    }

    // MARK: - Test Model
    private struct TestableModel: Hashable {
        let title: String
    }

    private class TestingMultiSelectViewModel: MultiSelectListViewModel<TestableModel> {
        var shownOptionsPicker = false

        override func showOptionsPicker(_ item: TestableModel) {
            shownOptionsPicker = true
        }
    }
}
