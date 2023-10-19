import PocketCastsServer
import PocketCastsUtils
import SwiftUI
import XCTest

@testable import podcasts

final class BookmarkAnnouncementViewModelTests: XCTestCase {
    private var subscriptionHelper: MockActiveTierSubscriptionHelper = .init()
    private var userDefaults: UserDefaults!

    override func setUp() {
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
    }

    // MARK: - Early Access Beta

    func testEarlyAccessBetaAnnouncementIsEnabledForPlus() {
        subscriptionHelper.userHasPlusSubscription()

        let model = model(featureTier: .plus, environment: .testFlight, inEarlyAccess: true)

        XCTAssertTrue(model.isEarlyAccessBetaAnnouncementEnabled)
    }

    func testEarlyAccessBetaAnnouncementIsEnabledForPatron() {
        subscriptionHelper.userHasPatronSubscription()

        let model = model(featureTier: .plus, environment: .testFlight, inEarlyAccess: true)

        XCTAssertTrue(model.isEarlyAccessBetaAnnouncementEnabled)
    }

    func testEarlyAccessBetaAnnouncementIsDisabledForNoSubscription() {
        subscriptionHelper.userHasNoSubscription()

        let model = model(featureTier: .plus, environment: .testFlight, inEarlyAccess: true)

        XCTAssertFalse(model.isEarlyAccessBetaAnnouncementEnabled)
    }

    func testEarlyAccessBetaAnnouncementIsDisabledInRelease() {
        subscriptionHelper.userHasPlusSubscription()

        let model = model(featureTier: .plus, environment: .appStore, inEarlyAccess: true)

        XCTAssertFalse(model.isEarlyAccessBetaAnnouncementEnabled)
    }

    // MARK: - Early Access Release

    func testEarlyAccessIsEnabledForPatron() {
        subscriptionHelper.userHasPatronSubscription()

        let model = model(featureTier: .plus, environment: .appStore, inEarlyAccess: true)

        XCTAssertTrue(model.isEarlyAccessAnnouncementEnabled)
    }

    func testEarlyAccessIsDisabledForPlus() {
        subscriptionHelper.userHasPlusSubscription()

        let model = model(featureTier: .plus, environment: .appStore, inEarlyAccess: true)

        XCTAssertFalse(model.isEarlyAccessAnnouncementEnabled)
    }

    func testEarlyAccessIsDisabledForNoSubscription() {
        subscriptionHelper.userHasNoSubscription()

        let model = model(featureTier: .plus, environment: .appStore, inEarlyAccess: true)

        XCTAssertFalse(model.isEarlyAccessAnnouncementEnabled)
    }

    func testEarlyAccessBetaAnnouncementIsDisabledInBeta() {
        subscriptionHelper.userHasPlusSubscription()

        let model = model(featureTier: .plus, environment: .testFlight, inEarlyAccess: true)

        XCTAssertFalse(model.isEarlyAccessAnnouncementEnabled)
    }

    // MARK: - Full Release

    func testFullReleaseAnnouncementIsEnabledInBeta() {
        let model = model(featureTier: .plus, environment: .testFlight)

        XCTAssertTrue(model.isReleaseAnnouncementEnabled)
    }

    func testFullReleaseAnnouncementIsEnabledInRelease() {
        let model = model(featureTier: .plus, environment: .appStore)

        XCTAssertTrue(model.isReleaseAnnouncementEnabled)
    }

    func testFullReleaseIsEnabledForNoSubscription() {
        subscriptionHelper.userHasNoSubscription()

        let model = model(featureTier: .plus, environment: .appStore)

        XCTAssertTrue(model.isReleaseAnnouncementEnabled)
    }

    func testFullReleaseIsEnabledForPlus() {
        subscriptionHelper.userHasPlusSubscription()

        let model = model(featureTier: .plus, environment: .appStore)

        XCTAssertTrue(model.isReleaseAnnouncementEnabled)
    }

    func testFullReleaseIsEnabledForPatron() {
        subscriptionHelper.userHasPatronSubscription()

        let model = model(featureTier: .plus, environment: .appStore)

        XCTAssertTrue(model.isReleaseAnnouncementEnabled)
    }

    func testFullReleaseIsDisabledForPeopleWhoSawItBefore() {
        let model = model(featureTier: .plus, environment: .appStore)
        model.markAsSeen()

        XCTAssertFalse(model.isReleaseAnnouncementEnabled)
    }

    // MARK: - Display Tier

    func testDisplayTierIsShownForEarlyAccess() {
        let tier = SubscriptionTier.plus

        let betaModel = model(featureTier: tier, environment: .testFlight, inEarlyAccess: true)
        XCTAssertEqual(betaModel.displayTier, tier)

        let appStoreModel = model(featureTier: tier, environment: .appStore, inEarlyAccess: true)
        XCTAssertEqual(appStoreModel.displayTier, tier)
    }

    func testDisplayTierIsHiddenWhenFeatureIsUnlockedInFullRelease() {
        subscriptionHelper.userHasPatronSubscription()
        let model = model(featureTier: .plus, environment: .appStore, inEarlyAccess: false)
        XCTAssertEqual(model.displayTier, .none)
    }

    func testDisplayTierIsShownWhenNotUnlockedInFullRelease() {
        let tier = SubscriptionTier.plus

        subscriptionHelper.userHasNoSubscription()
        let model = model(featureTier: .plus, environment: .appStore, inEarlyAccess: false)
        XCTAssertEqual(model.displayTier, tier)
    }
}

private extension BookmarkAnnouncementViewModelTests {
    func model(featureTier: SubscriptionTier, environment: BuildEnvironment, inEarlyAccess: Bool = false) -> BookmarkAnnouncementViewModel {
        let feature = PaidFeature(tier: featureTier,
                                  inEarlyAccess: inEarlyAccess,
                                  subscriptionHelper: subscriptionHelper,
                                  buildEnvironment: environment)

        return BookmarkAnnouncementViewModel(feature: feature,
                                             buildEnvironment: environment,
                                             activeTier: subscriptionHelper.activeTier,
                                             userDefaults: userDefaults)
    }
}
