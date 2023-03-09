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
}
