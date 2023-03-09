import XCTest

@testable import podcasts

class SearchHistoryModelTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var model: SearchHistoryModel!

    override func setUp() {
        userDefaults = UserDefaults(suiteName: "SearchHistoryModelTests")
        userDefaults.removePersistentDomain(forName: "SearchHistoryModelTests")

        model = SearchHistoryModel(userDefaults: userDefaults)
    }

    // MARK: - Add entries

    func testAddEntry() {
        model.add(searchTerm: "foo")

        XCTAssertEqual(model.entries.first, SearchHistoryEntry(searchTerm: "foo"))
    }

    func testEntryIsPersisted() {
        model.add(searchTerm: "foo")

        let newModelInstance = SearchHistoryModel(userDefaults: userDefaults)

        XCTAssertEqual(newModelInstance.entries.first, SearchHistoryEntry(searchTerm: "foo"))
    }

    func testAddMultipleEntries() {
        model.add(searchTerm: "foo")
        model.add(searchTerm: "bar")
        model.add(searchTerm: "john")
        model.add(searchTerm: "doe")

        XCTAssertEqual(model.entries, [SearchHistoryEntry(searchTerm: "doe"), SearchHistoryEntry(searchTerm: "john"), SearchHistoryEntry(searchTerm: "bar"), SearchHistoryEntry(searchTerm: "foo")])
    }

    func testSameEntryIsNotAddedTwice() {
        model.add(searchTerm: "foo")
        model.add(searchTerm: "bar")
        model.add(searchTerm: "foo")

        XCTAssertEqual(model.entries, [SearchHistoryEntry(searchTerm: "foo"), SearchHistoryEntry(searchTerm: "bar")])
    }

    // MARK: - Removal

    func testRemoveEntry() {
        model.add(searchTerm: "foo")
        model.add(searchTerm: "bar")

        model.remove(entry: SearchHistoryEntry(searchTerm: "foo"))

        XCTAssertEqual(model.entries, [SearchHistoryEntry(searchTerm: "bar")])
    }

    func testRemoveAllEntries() {
        model.add(searchTerm: "foo")
        model.add(searchTerm: "bar")

        model.removeAll()

        XCTAssertTrue(model.entries.isEmpty)
    }

    // MARK: Limit

    func testAddAMaximumOf10Entries() {
        model.add(searchTerm: "1")
        model.add(searchTerm: "2")
        model.add(searchTerm: "3")
        model.add(searchTerm: "4")
        model.add(searchTerm: "5")
        model.add(searchTerm: "6")
        model.add(searchTerm: "7")
        model.add(searchTerm: "8")
        model.add(searchTerm: "9")
        model.add(searchTerm: "10")
        model.add(searchTerm: "11")

        XCTAssertEqual(model.entries.count, 10)
    }
}
