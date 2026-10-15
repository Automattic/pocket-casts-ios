@testable import podcasts
import PocketCastsServer
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

    func testUpsellRouteOffersPlusToFreeAccount() {
        XCTAssertEqual(OnboardingFlow.Flow(upsellRouteTier: .none), .plusUpsell)
    }

    func testUpsellRouteOffersOnlyPatronToPlusAccount() {
        XCTAssertEqual(OnboardingFlow.Flow(upsellRouteTier: .plus), .patronAccountUpgrade)
    }

    func testUpsellRouteOffersNothingToPatronAccount() {
        XCTAssertNil(OnboardingFlow.Flow(upsellRouteTier: .patron))
    }
}
