import Foundation
import PocketCastsServer

class DiscoverCoordinator {
    private let subscriptionData: SubscriptionHelper.Type

    init(subscriptionData: SubscriptionHelper.Type = SubscriptionHelper.self) {
        self.subscriptionData = subscriptionData
    }

    func shouldDisplay(_ item: DiscoverItem) -> Bool {
        true
    }
}
