import PocketCastsUtils
import XCTest

class PodcastSorterTests: XCTestCase {
    func testTitleSort() {
        let tests = [
            // Ascending order
            ["A title", "B title"],
            // Ignores "The"
            ["The A title", "B title"],
            ["A title", "The B title"],
            ["The A title", "The B title"],
            // case-insensitive
            ["a title", "B TITLE"],
            ["A TITLE", "b title"],
            // emoji sorting
            ["B title", "🔚 A title"],
            ["🔥 A title", "🔥 B title"],
            ["🔚 A title", "🔥 A title"],
            // Chinese to pinyin sorting: 昂 = áng, 奥 = ào, 备 = bèi
            ["昂 áng title", "B title"],
            ["昂 áng title", "奥 ào title"],
            ["奥 ào title", "备 bèi title"],
            ["B title", "备 bèi title"]
        ]

        tests.forEach {
            XCTAssertTrue(PodcastSorter.titleSort(title1: $0[0], title2: $0[1]))
        }

        tests.forEach {
            XCTAssertFalse(PodcastSorter.titleSort(title1: $0[1], title2: $0[0]))
        }

        // same string
        XCTAssertFalse(PodcastSorter.titleSort(title1: "A title", title2: "A title"))
    }

    func testCustomSort() {
        XCTAssertTrue(PodcastSorter.customSort(order1: 1, order2: 2))
        XCTAssertFalse(PodcastSorter.customSort(order1: 2, order2: 2))
        XCTAssertFalse(PodcastSorter.customSort(order1: 3, order2: 2))
    }

    func testDateSort() {
        let now = Date()
        let fiveMinutesFromNow = Date(timeIntervalSinceNow: 5.minutes)

        XCTAssertTrue(PodcastSorter.dateAddedSort(date1: now, date2: fiveMinutesFromNow))
        XCTAssertFalse(PodcastSorter.dateAddedSort(date1: now, date2: now))
        XCTAssertFalse(PodcastSorter.dateAddedSort(date1: fiveMinutesFromNow, date2: now))
    }
}
