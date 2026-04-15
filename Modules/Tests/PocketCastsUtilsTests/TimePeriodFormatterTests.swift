import PocketCastsUtils
import XCTest

class TimePeriodFormatterTests: XCTestCase {
    func testZeroesReturnPlural() {
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 0, unit: .day), "0 days")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 0, unit: .weekOfMonth), "0 weeks")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 0, unit: .month), "0 months")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 0, unit: .year), "0 years")
    }

    func testOneReturnsSingular() {
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1, unit: .day), "1 day")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1, unit: .weekOfMonth), "1 week")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1, unit: .month), "1 month")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1, unit: .year), "1 year")
    }

    func testMoreThanOneReturnsPlural() {
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 2, unit: .day), "2 days")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 4, unit: .weekOfMonth), "4 weeks")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 6, unit: .month), "6 months")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 8, unit: .year), "8 years")
    }

    func testThousandsHaveCommas() {
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .day), "1,000 days")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .weekOfMonth), "1,000 weeks")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .month), "1,000 months")
        XCTAssertEqual(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .year), "1,000 years")
    }

    func testInvalidUnitValueReturnsNil() {
        XCTAssertNil(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .weekdayOrdinal))
        XCTAssertNil(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .quarter))
        XCTAssertNil(TimePeriodFormatter.format(numberOfUnits: 1000, unit: .nanosecond))
    }
}
