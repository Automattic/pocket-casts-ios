import Foundation
import PocketCastsUtils
import XCTest

final class KMPSearchTests: XCTestCase {
    // Empty pattern and search subject should return empty indices
    func testEmptySearch() throws {
        let kpmSearch = KMPSearch(text: "")

        let indices = kpmSearch.search(for: "")

        XCTAssertTrue(indices.isEmpty)
    }

    // Empty pattern returns empty indices
    func testEmptyPattern() throws {
        let kpmSearch = KMPSearch(text: "Lorem Ipsum")

        let indices = kpmSearch.search(for: "")

        XCTAssertTrue(indices.isEmpty)
    }

    // Return the correct indice for a given word
    func testGivenWord() throws {
        let kpmSearch = KMPSearch(text: "Lorem Ipsum")

        let indices = kpmSearch.search(for: "Lorem")

        XCTAssertEqual(indices, [0])
    }

    // Ensure search is case-insensitive
    func testCaseInsensitive() throws {
        let kpmSearch = KMPSearch(text: "Lorem Ipsum")

        let indices = kpmSearch.search(for: "lorem")

        XCTAssertEqual(indices, [0])
    }

    // Ensure search handles diacritics
    func testHandleDiacritics() throws {
        let kpmSearch = KMPSearch(text: "um avião pra voar")

        let indices = kpmSearch.search(for: "aviao")

        XCTAssertEqual(indices, [3])
    }

    // Ensure search handles diacritics and the letter ł
    func testHandleDiacriticsOtherWay() throws {
        let kpmSearch = KMPSearch(text: "lorem zolc ipsum")

        let indices = kpmSearch.search(for: "żółć")

        XCTAssertEqual(indices, [6])
    }

    // Ensure search return all results
    func testAllResults() throws {
        let kpmSearch = KMPSearch(text: "One two One Two One Two One Two")

        let indices = kpmSearch.search(for: "one")

        XCTAssertEqual(indices, [0, 8, 16, 24])
    }
}
