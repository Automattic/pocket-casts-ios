import XCTest

@testable import podcasts
import PocketCastsServer

final class PaidFeatureTests: XCTestCase {
    private var subscriptionHelper: MockSubscriptionHelper! = .init()

    override func setUp() {
        subscriptionHelper = .init()
    }

    // MARK: - Free Features

    func testFreeFeatureIsUnlockedForNoActiveSubscription() {
        let feature = freeFeature()

        subscriptionHelper.userHasNoSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    func testFreeFeatureIsUnlockedForPlusSubscription() {
        let feature = freeFeature()

        subscriptionHelper.userHasPlusSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    func testFreeFeatureIsUnlockedForPatronSubscription() {
        let feature = freeFeature()

        subscriptionHelper.userHasPatronSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    // MARK: - Plus Features

    func testPlusFeatureIsLockedForNoActiveSubscription() {
        let feature = plusFeature()

        subscriptionHelper.userHasNoSubscription()

        XCTAssertFalse(feature.isUnlocked)
    }

    func testPlusFeatureIsUnlockedForPlusSubscription() {
        let feature = plusFeature()

        subscriptionHelper.userHasPlusSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    func testPlusFeatureIsUnlockedForPatronSubscription() {
        let feature = plusFeature()

        subscriptionHelper.userHasPatronSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    // MARK: - Patron Features

    func testPatronFeatureIsLockedForNoActiveSubscription() {
        let feature = patronFeature()

        subscriptionHelper.userHasNoSubscription()

        XCTAssertFalse(feature.isUnlocked)
    }

    func testPatronFeatureIsLockedForPlusSubscription() {
        let feature = patronFeature()

        subscriptionHelper.userHasPlusSubscription()

        XCTAssertFalse(feature.isUnlocked)
    }

    func testPatronFeatureIsUnlockedForPatronSubscription() {
        let feature = patronFeature()

        subscriptionHelper.userHasPatronSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    // MARK: - Beta Testing

    func testPatronFeatureWithBetaPlusIsUnlockedInBeta() {
        let feature = PaidFeature(tier: .patron,
                                  betaTier: .plus,
                                  subscriptionHelper: subscriptionHelper,
                                  buildEnvironment: .testFlight)

        subscriptionHelper.userHasPlusSubscription()

        XCTAssertTrue(feature.isUnlocked)
    }

    func testPatronFeatureWithBetaPlusIsLockedForAppStore() {
        let feature = PaidFeature(tier: .patron,
                                  betaTier: .plus,
                                  subscriptionHelper: subscriptionHelper,
                                  buildEnvironment: .appStore)

        subscriptionHelper.userHasPlusSubscription()

        XCTAssertFalse(feature.isUnlocked)
    }

    // MARK: - Private
    private func freeFeature() -> PaidFeature {
        feature(tier: .none)
    }

    private func plusFeature() -> PaidFeature {
        feature(tier: .plus)
    }

    private func patronFeature() -> PaidFeature {
        feature(tier: .patron)
    }

    private func feature(tier: SubscriptionTier) -> PaidFeature {
        PaidFeature(tier: tier, subscriptionHelper: subscriptionHelper)
    }
}

// MARK: - Mocks
private class MockSubscriptionHelper: SubscriptionHelper {
    var _activeTier: SubscriptionTier = .none

    override var activeTier: SubscriptionTier {
        _activeTier
    }

    func userHasNoSubscription() {
        _activeTier = .none
    }

    func userHasPlusSubscription() {
        _activeTier = .plus
    }

    func userHasPatronSubscription() {
        _activeTier = .patron
    }
}
