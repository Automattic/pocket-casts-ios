import Foundation
import PocketCastsUtils
import XCTest

final class KMPSearchTests: XCTestCase {
    // Empty pattern and search subject should return empty indices
    func testEmptySearch() throws {
        let kpmSearch = KMPSearch(pattern: "")

        let indices = kpmSearch.search(in: "")

        XCTAssertTrue(indices.isEmpty)
    }

    // Empty pattern returns empty indices
    func testEmptyPattern() throws {
        let kpmSearch = KMPSearch(pattern: "")

        let indices = kpmSearch.search(in: "Lorem Ipsum")

        XCTAssertTrue(indices.isEmpty)
    }

    // Return the correct indice for a given word
    func testGivenWord() throws {
        let kpmSearch = KMPSearch(pattern: "Lorem")

        let indices = kpmSearch.search(in: "Lorem Ipsum")

        XCTAssertEqual(indices, [0])
    }

    // Ensure search is case-insensitive
    func testCaseInsensitive() throws {
        let kpmSearch = KMPSearch(pattern: "lorem")

        let indices = kpmSearch.search(in: "Lorem Ipsum")

        XCTAssertEqual(indices, [0])
    }

    // Ensure search return all results
    func testAllResults() throws {
        let kpmSearch = KMPSearch(pattern: "one")

        let indices = kpmSearch.search(in: "One two One Two One Two One Two")

        XCTAssertEqual(indices, [0, 8, 16, 24])
    }
}
