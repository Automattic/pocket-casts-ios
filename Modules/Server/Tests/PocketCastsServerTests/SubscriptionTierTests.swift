import Foundation
@testable import PocketCastsServer
import XCTest

final class SubscriptionTierTests: XCTestCase {
    func testSubscriptionNoneIsLessThanEverything() {
        XCTAssertLessThan(SubscriptionTier.none, SubscriptionTier.plus)
        XCTAssertLessThan(SubscriptionTier.none, SubscriptionTier.patron)
    }

    func testSubscriptionPlusIsLessThanPatron() {
        XCTAssertLessThan(SubscriptionTier.plus, SubscriptionTier.patron)
    }

    func testSubscriptionPatronIsMoreThanEverythingElse() {
        XCTAssertGreaterThan(SubscriptionTier.patron, SubscriptionTier.plus)
        XCTAssertGreaterThan(SubscriptionTier.patron, SubscriptionTier.none)
    }
}
