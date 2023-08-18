import XCTest

@testable import podcasts
import PocketCastsServer

final class PaidFeatureTests: XCTestCase {
    override func setUp() {
        TestSubscriptionHelper.noSubscription()
    }

    func testFreeFeatureIsAlwaysUnlocked() {
        assertTierValues(tier: .none, free: true, plus: true, patron: true)
    }

    func testPlusFeatureIsUnlockedForPlusAndPatron() {
        assertTierValues(tier: .plus, free: false, plus: true, patron: true)
    }

    func testPatronFeatureIsUnlockedForOnlyPatron() {
        assertTierValues(tier: .patron, free: false, plus: false, patron: true)
    }

    func assertTierValues(tier: SubscriptionTier, free: Bool, plus: Bool, patron: Bool) {
        let feature = feature(tier: tier)

        XCTAssertEqual(feature.isUnlocked, free)

        TestSubscriptionHelper.activePlus()
        XCTAssertEqual(feature.isUnlocked, plus)

        TestSubscriptionHelper.activePatron()
        XCTAssertEqual(feature.isUnlocked, patron)
    }

    private func feature(tier: SubscriptionTier) -> PaidFeature {
        PaidFeature(tier: tier, subscriptionHelper: TestSubscriptionHelper.self)
    }
}

private class TestSubscriptionHelper: SubscriptionHelper {
    static var _hasActiveSubscription: Bool = false
    static var _subscriptionTier: SubscriptionTier = .none

    override class func hasActiveSubscription() -> Bool {
        _hasActiveSubscription
    }

    override class var subscriptionTier: SubscriptionTier {
        set { _subscriptionTier = newValue }
        get { _subscriptionTier }
    }

    static func noSubscription() {
        _hasActiveSubscription = false
        _subscriptionTier = .none
    }

    static func activePlus() {
        _hasActiveSubscription = true
        _subscriptionTier = .plus
    }

    static func activePatron() {
        _hasActiveSubscription = true
        _subscriptionTier = .patron
    }
}
