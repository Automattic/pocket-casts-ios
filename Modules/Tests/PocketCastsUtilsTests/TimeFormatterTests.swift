import PocketCastsUtils
import XCTest

class TimeFormatterTests: XCTestCase {
    func testElapsedStringForCurrentDateIsNow() {
        XCTAssertEqual(TimeFormatter.shared.appleStyleElapsedString(date: Date()), "now")
    }

    func testElapsedStringForDateSlightlyInTheFutureIsNow() {
        XCTAssertEqual(TimeFormatter.shared.appleStyleElapsedString(date: Date().addingTimeInterval(0.5)), "now")
    }

    func testElapsedStringForDateSlightlyInThePastIsNow() {
        XCTAssertEqual(TimeFormatter.shared.appleStyleElapsedString(date: Date().addingTimeInterval(-0.5)), "now")
    }

    func testElapsedStringForPastDates() {
        XCTAssertEqual(TimeFormatter.shared.appleStyleElapsedString(date: Date().addingTimeInterval(-5)), "5 seconds ago")
        XCTAssertEqual(TimeFormatter.shared.appleStyleElapsedString(date: Date().addingTimeInterval(-2 * 60 * 60)), "2 hours ago")
    }
}
