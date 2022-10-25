import Foundation
import PocketCastsServer

class DiscoverCoordinator {
    private let subscriptionData: SubscriptionHelper.Type

    init(subscriptionData: SubscriptionHelper.Type = SubscriptionHelper.self) {
        self.subscriptionData = subscriptionData
    }

    func shouldDisplay(_ item: DiscoverItem) -> Bool {
        let platform = subscriptionData.subscriptionPlatform()
        let isSponsored = item.isSponsored ?? false

        // don't show sponsored items to active plus subscribers. Those who don't have a subscription, or have a gift (lifetime or otherwise) will still get them
        if isSponsored, subscriptionData.hasActiveSubscription(), platform.isPaidSubscriptionPlatform {
            return false
        }

        return true
    }
}
