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

    func testUnlocksAfterIAPPurchase() {
        assertUnlockedAfterNotification(ServerNotifications.iapPurchaseCompleted)
    }

    func testUnlocksAfterSubscriptionStatusChanged() {
        assertUnlockedAfterNotification(ServerNotifications.subscriptionStatusChanged)
    }

    func assertUnlockedAfterNotification(_ name: Notification.Name) {
        let feature = feature(tier: .patron)

        XCTAssertFalse(feature.isUnlocked)

        TestSubscriptionHelper.activePatron()

        NotificationCenter.default.post(name: name, object: nil)

        eventually {
            XCTAssertTrue(feature.isUnlocked)
        }
    }

    func assertTierValues(tier: SubscriptionTier, free: Bool, plus: Bool, patron: Bool) {
        TestSubscriptionHelper.noSubscription()
        XCTAssertEqual(feature(tier: tier).isUnlocked, free)

        TestSubscriptionHelper.activePlus()
        XCTAssertEqual(feature(tier: tier).isUnlocked, plus)

        TestSubscriptionHelper.activePatron()
        XCTAssertEqual(feature(tier: tier).isUnlocked, patron)
    }

    private func feature(tier: SubscriptionTier) -> PaidFeature {
        PaidFeature(tier: tier, subscriptionHelper: TestSubscriptionHelper.self)
    }
}

private class TestSubscriptionHelper: SubscriptionHelper {
    static var _hasActiveSubscription: Bool = false
    static var _subscriptionType: SubscriptionType = .none
    static var _subscriptionTier: SubscriptionTier = .none

    override class func hasActiveSubscription() -> Bool {
        _hasActiveSubscription
    }

    override class func subscriptionType() -> SubscriptionType {
        _subscriptionType
    }

    override class var subscriptionTier: SubscriptionTier {
        set {
            _subscriptionTier = newValue
        }

        get {
            _subscriptionTier
        }
    }

    static func noSubscription() {
        _hasActiveSubscription = false
        _subscriptionTier = .none
        _subscriptionType = .none
    }

    static func activePlus() {
        _hasActiveSubscription = true
        _subscriptionTier = .plus
        _subscriptionType = .plus
    }

    static func activePatron() {
        _hasActiveSubscription = true
        _subscriptionTier = .patron
        _subscriptionType = .plus
    }
}
