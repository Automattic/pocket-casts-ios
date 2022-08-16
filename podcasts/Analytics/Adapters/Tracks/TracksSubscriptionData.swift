import Foundation
import PocketCastsServer

/// Abstraction to return information about the susbcriptions
protocol TracksSubscriptionData {
    func hasActiveSubscription() -> Bool
    func subscriptionPlatform() -> SubscriptionPlatform
    func subscriptionType() -> SubscriptionType
    func subscriptionFrequency() -> SubscriptionFrequency
    func hasLifetimeGift() -> Bool
}

/// Retrieves Pocket Casts specific data for use in tracks
struct PocketCastsTracksSubscriptionData: TracksSubscriptionData {
    func hasActiveSubscription() -> Bool {
        SubscriptionHelper.hasActiveSubscription()
    }

    func subscriptionPlatform() -> SubscriptionPlatform {
        SubscriptionHelper.subscriptionPlatform()
    }

    func subscriptionType() -> SubscriptionType {
        SubscriptionHelper.subscriptionType()
    }

    func subscriptionFrequency() -> SubscriptionFrequency {
        SubscriptionHelper.subscriptionFrequencyValue()
    }

    func hasLifetimeGift() -> Bool {
        SubscriptionHelper.hasLifetimeGift()
    }
}
