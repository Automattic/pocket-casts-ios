@testable import podcasts
import XCTest

@MainActor
final class MultiSelectableTests: XCTestCase {
    private var list = TestableList()

    // MARK: - Entering / Exiting Multi Selection

    func testToggleMultiSelectionEntersCorrectly() {
        XCTAssertFalse(list.isMultiSelecting)

        list.toggleMultiSelection()
        XCTAssertTrue(list.isMultiSelecting)
    }

    func testToggleMultiSelectionExitsCorrectly() {
        // Enter
        list.toggleMultiSelection()

        // Exit
        list.toggleMultiSelection()

        XCTAssertFalse(list.isMultiSelecting)
    }

    func testExitingMultiSelectionResetsSelection() {
        list.toggleMultiSelection()
        list.toggleSelected(list.selectableItems.first!)

        list.toggleMultiSelection()
        XCTAssertTrue(list.selectedItems.isEmpty)
    }

    func testEmptyingTheListExitsMultiSelection() {
        list.toggleMultiSelection()
        list.toggleSelectAll()

        list.selectableItems = []
        list.selectableItemsDidChange()

        XCTAssertFalse(list.isMultiSelecting)
    }

    func testShorteningTheListStaysInMultiSelection() {
        list.toggleMultiSelection()

        list.selectableItems.removeLast()
        list.selectableItemsDidChange()

        XCTAssertTrue(list.isMultiSelecting)
    }

    // MARK: - Selection Toggling

    func testToggleSelected() {
        // Select the last item first
        list.toggleSelected(list.selectableItems.last!)
        XCTAssertTrue(list.isSelected(list.selectableItems.last!))
        XCTAssertFalse(list.isSelected(list.selectableItems.first!))

        // Select first and last
        list.toggleSelected(list.selectableItems.first!)
        XCTAssertTrue(list.isSelected(list.selectableItems.last!))
        XCTAssertTrue(list.isSelected(list.selectableItems.first!))

        // Deselect the last item
        list.toggleSelected(list.selectableItems.last!)

        XCTAssertFalse(list.isSelected(list.selectableItems.last!))
        XCTAssertTrue(list.isSelected(list.selectableItems.first!))
    }

    func testSelectedItemsFollowTheOrderOfTheList() {
        list.toggleSelected(list.selectableItems[2])
        list.toggleSelected(list.selectableItems[0])

        XCTAssertEqual(list.selectedItems, [list.selectableItems[0], list.selectableItems[2]])
    }

    /// Only the ids are kept, so items that leave the list stop counting as selected
    func testItemsRemovedFromTheListAreNotSelected() {
        list.toggleSelectAll()

        list.selectableItems.remove(at: 1)

        XCTAssertEqual(list.selectedItems.count, 2)
        XCTAssertTrue(list.hasSelectedAll)
    }

    // MARK: - Select/Deselect All

    func testToggleSelectAll() {
        XCTAssertFalse(list.hasSelectedAll)

        list.toggleSelectAll()
        XCTAssertTrue(list.hasSelectedAll)
        XCTAssertEqual(list.selectedItems.count, list.selectableItems.count)

        list.toggleSelectAll()
        XCTAssertFalse(list.hasSelectedAll)
        XCTAssertTrue(list.selectedItems.isEmpty)
    }

    func testHasSelectedAllIsFalseForAnEmptyList() {
        list.selectableItems = []

        XCTAssertFalse(list.hasSelectedAll)
    }

    // MARK: - Select All Before

    func testSelectAllBefore() {
        let item = list.selectableItems[1]
        list.selectAllBefore(item)

        XCTAssertTrue(list.isSelected(list.selectableItems[0]))
        XCTAssertTrue(list.isSelected(list.selectableItems[1]))
        XCTAssertFalse(list.isSelected(list.selectableItems[2]))
    }

    func testSelectAllBeforeDoesNothingIfMissing() {
        let item = list.selectableItems[1]
        list.selectableItems.remove(at: 1)

        list.selectAllBefore(item)

        XCTAssertTrue(list.selectedItems.isEmpty)
    }

    func testDeselectAllBefore() {
        list.toggleSelectAll()

        list.deselectAllBefore(list.selectableItems[1])

        XCTAssertEqual(list.selectedItems, [list.selectableItems[2]])
    }

    func testHasSelectedAllBefore() {
        let item = list.selectableItems[1]
        XCTAssertFalse(list.hasSelectedAllBefore(item))

        list.selectAllBefore(item)

        XCTAssertTrue(list.hasSelectedAllBefore(item))
    }

    func testHasSelectedAllBeforeIsFalseIfMissing() {
        let item = list.selectableItems[1]
        list.toggleSelectAll()
        list.selectableItems.remove(at: 1)

        XCTAssertFalse(list.hasSelectedAllBefore(item))
    }

    // MARK: - Select All After

    func testSelectAllAfter() {
        let item = list.selectableItems[1]
        list.selectAllAfter(item)

        XCTAssertFalse(list.isSelected(list.selectableItems[0]))
        XCTAssertTrue(list.isSelected(list.selectableItems[1]))
        XCTAssertTrue(list.isSelected(list.selectableItems[2]))
    }

    func testSelectAllAfterDoesNothingIfMissing() {
        let item = list.selectableItems[1]
        list.selectableItems.remove(at: 1)

        list.selectAllAfter(item)

        XCTAssertTrue(list.selectedItems.isEmpty)
    }

    func testDeselectAllAfter() {
        list.toggleSelectAll()

        list.deselectAllAfter(list.selectableItems[1])

        XCTAssertEqual(list.selectedItems, [list.selectableItems[0]])
    }

    func testHasSelectedAllAfter() {
        let item = list.selectableItems[1]
        XCTAssertFalse(list.hasSelectedAllAfter(item))

        list.selectAllAfter(item)

        XCTAssertTrue(list.hasSelectedAllAfter(item))
    }

    func testHasSelectedAllAfterIsFalseIfMissing() {
        let item = list.selectableItems[1]
        list.toggleSelectAll()
        list.selectableItems.remove(at: 1)

        XCTAssertFalse(list.hasSelectedAllAfter(item))
    }

    // MARK: - Long Press

    func testLongPressEntersMultiSelection() {
        let item = list.selectableItems[1]
        list.longPressed(item)

        // enter multi select, and select the item that was pressed
        XCTAssertTrue(list.isMultiSelecting)
        XCTAssertTrue(list.isSelected(item))
    }
}

// MARK: - Test Model

private struct TestableModel: Identifiable, Equatable {
    let title: String

    var id: String { title }
}

@MainActor
private final class TestableList: MultiSelectable {
    var selectableItems: [TestableModel] = [
        .init(title: "one"),
        .init(title: "two"),
        .init(title: "three")
    ]

    var isMultiSelecting = false
    var selectedIDs: Set<TestableModel.ID> = []
}
