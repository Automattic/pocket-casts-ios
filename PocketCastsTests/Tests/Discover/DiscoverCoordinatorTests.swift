import Foundation
@testable import podcasts
@testable import PocketCastsServer
import XCTest

final class DiscoverCoordinatorTests: XCTestCase {
    private var coordinator: DiscoverCoordinator!
    private var subscriptionData: MockSubscriptionHelper.Type!

    override func setUp() {
        subscriptionData = MockSubscriptionHelper.self
        coordinator = DiscoverCoordinator(subscriptionData: subscriptionData)
    }

    func testDoesNotDisplayWithPaidPlatforms() throws {
        let item = try DiscoverItem.make(isSponsored: true)
        subscriptionData.mockHasActiveSubscription = true

        subscriptionData.mocksubscriptionPlatform = .iOS
        XCTAssertFalse(coordinator.shouldDisplay(item))

        subscriptionData.mocksubscriptionPlatform = .web
        XCTAssertFalse(coordinator.shouldDisplay(item))

        subscriptionData.mocksubscriptionPlatform = .android
        XCTAssertFalse(coordinator.shouldDisplay(item))
    }

    func testDoesNotDisplayWithActiveSubscription() throws {
        let item = try DiscoverItem.make(isSponsored: true)
        subscriptionData.mockHasActiveSubscription = true
        subscriptionData.mocksubscriptionPlatform = .iOS

        XCTAssertFalse(coordinator.shouldDisplay(item))
    }

    func testDisplaysWithoutActiveSubscription() throws {
        let item = try DiscoverItem.make(isSponsored: true)
        subscriptionData.mockHasActiveSubscription = false
        subscriptionData.mocksubscriptionPlatform = .none

        XCTAssertTrue(coordinator.shouldDisplay(item))
    }

    func testDisplaysNormalDiscoverItem() throws {
        let item = try DiscoverItem.make(isSponsored: false)
        subscriptionData.mockHasActiveSubscription = true
        subscriptionData.mocksubscriptionPlatform = .web

        XCTAssertTrue(coordinator.shouldDisplay(item))
    }
}

// MARK: - Mocks
private class MockSubscriptionHelper: SubscriptionHelper {
    static var mockHasActiveSubscription: Bool = false
    static var mocksubscriptionPlatform: SubscriptionPlatform = .none

    override class func hasActiveSubscription() -> Bool {
        return mockHasActiveSubscription
    }

    override class func subscriptionPlatform() -> SubscriptionPlatform {
        return mocksubscriptionPlatform
    }
}

private extension DiscoverItem {
    static func make(isSponsored: Bool) throws -> DiscoverItem {
        let decoder = JSONDecoder()

        let data = Data("{\"sponsored\": \(isSponsored), \"regions\": [\"us\"]}".utf8)
        return try decoder.decode(DiscoverItem.self, from: data)
    }
}
