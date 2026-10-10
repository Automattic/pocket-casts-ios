import XCTest
@testable import podcasts

final class UnplayedBadgeTests: XCTestCase {
    func testCountsUpTo99ShowTheExactNumber() {
        XCTAssertEqual(UnplayedBadge.text(forCount: 1), "1")
        XCTAssertEqual(UnplayedBadge.text(forCount: 98), "98")
        XCTAssertEqual(UnplayedBadge.text(forCount: 99), "99")
    }

    func testCountsAbove99ShowAPlus() {
        XCTAssertEqual(UnplayedBadge.text(forCount: 100), "99+")
        XCTAssertEqual(UnplayedBadge.text(forCount: 176), "99+")
    }
}
