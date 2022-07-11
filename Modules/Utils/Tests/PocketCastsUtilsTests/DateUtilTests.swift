import Foundation
import PocketCastsUtils
import XCTest

final class DateUtilTests: XCTestCase {
    func test_if_enough_time_has_passed() throws {
        let sevenDaysAgo = Date(timeIntervalSinceNow: -7.days)
        let twelveHoursAgo = Date(timeIntervalSinceNow: -12.hours)
        let fiveMinutesAgo = Date(timeIntervalSinceNow: -5.minutes)
        let thirtySecondsAgo = Date(timeIntervalSinceNow: -30.seconds)
        // Test if enough time has passed:
        XCTAssertTrue(DateUtil.hasEnoughTimePassed(since: sevenDaysAgo, time: 6.days))
        XCTAssertTrue(DateUtil.hasEnoughTimePassed(since: twelveHoursAgo, time: 11.hours))
        XCTAssertTrue(DateUtil.hasEnoughTimePassed(since: fiveMinutesAgo, time: 4.minutes))
        XCTAssertTrue(DateUtil.hasEnoughTimePassed(since: thirtySecondsAgo, time: 15.seconds))
        // Test if not enough time has passed:
        XCTAssertFalse(DateUtil.hasEnoughTimePassed(since: sevenDaysAgo, time: 8.days))
        XCTAssertFalse(DateUtil.hasEnoughTimePassed(since: twelveHoursAgo, time: 13.hours))
        XCTAssertFalse(DateUtil.hasEnoughTimePassed(since: fiveMinutesAgo, time: 6.minutes))
        XCTAssertFalse(DateUtil.hasEnoughTimePassed(since: thirtySecondsAgo, time: 45.seconds))
    }
}
