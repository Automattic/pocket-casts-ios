import XCTest

@testable import podcasts
import PocketCastsServer

final class PaidFeatureTests: XCTestCase {
    override func setUp() {
        userHasNoSubscription()
    }

    // MARK: - Free Features

    func testFreeFeatureIsUnlockedForNoActiveSubscription() {
        userHasNoSubscription()
        XCTAssertTrue(feature(tier: .none).isUnlocked)
    }

    func testFreeFeatureIsUnlockedForPlusSubscription() {
        userHasPlus()
        XCTAssertTrue(feature(tier: .none).isUnlocked)
    }

    func testFreeFeatureIsUnlockedForPatronSubscription() {
        userHasPatron()
        XCTAssertTrue(feature(tier: .none).isUnlocked)
    }

    // MARK: - Plus Features

    func testPlusFeatureIsLockedForNoActiveSubscription() {
        userHasNoSubscription()
        XCTAssertFalse(feature(tier: .plus).isUnlocked)
    }

    func testPlusFeatureIsUnlockedForPlusSubscription() {
        userHasPlus()
        XCTAssertTrue(feature(tier: .plus).isUnlocked)
    }

    func testPlusFeatureIsUnLockedForPatronSubscription() {
        userHasPatron()
        XCTAssertTrue(feature(tier: .plus).isUnlocked)
    }

    // MARK: - Plus Features

    func testPatronFeatureIsLockedForNoActiveSubscription() {
        userHasNoSubscription()
        XCTAssertFalse(feature(tier: .patron).isUnlocked)
    }

    func testPatronFeatureIsLockedForPlusSubscription() {
        userHasPlus()
        XCTAssertFalse(feature(tier: .patron).isUnlocked)
    }

    func testPatronFeatureIsUnlockedForPatronSubscription() {
        userHasPatron()
        XCTAssertTrue(feature(tier: .patron).isUnlocked)
    }

    // MARK: - Private

    private func userHasNoSubscription() {
        TestSubscriptionHelper._hasActiveSubscription = false
        TestSubscriptionHelper._subscriptionTier = .none
    }

    private func userHasPlus() {
        TestSubscriptionHelper._hasActiveSubscription = true
        TestSubscriptionHelper._subscriptionTier = .plus
    }

    private func userHasPatron() {
        TestSubscriptionHelper._hasActiveSubscription = true
        TestSubscriptionHelper._subscriptionTier = .patron
    }

    private func feature(tier: SubscriptionTier) -> PaidFeature {
        PaidFeature(tier: tier, subscriptionHelper: TestSubscriptionHelper.self)
    }
}

// MARK: - Mocks

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
}
