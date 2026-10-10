@testable import podcasts
import XCTest

final class PlusUpgradeViewSourceRouteTests: XCTestCase {
    func testKnownSourceIsUsed() {
        XCTAssertEqual(PlusUpgradeViewSource(routeParameters: ["source": "profile"]), .profile)
        XCTAssertEqual(PlusUpgradeViewSource(routeParameters: ["source": "banner_ad"]), .bannerAd)
    }

    func testMissingSourceDefaultsToDeepLink() {
        XCTAssertEqual(PlusUpgradeViewSource(routeParameters: [:]), .deepLink)
    }

    func testUnknownSourceIsUnknown() {
        XCTAssertEqual(PlusUpgradeViewSource(routeParameters: ["source": "not_a_source"]), .unknown)
    }
}
