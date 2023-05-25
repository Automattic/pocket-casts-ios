import Foundation
import PocketCastsServer

/// Abstraction to return information about the subcriptions
protocol TracksSubscriptionData {
    func hasActiveSubscription() -> Bool
    func subscriptionPlatform() -> SubscriptionPlatform
    func subscriptionType() -> SubscriptionType
    func subscriptionFrequency() -> SubscriptionFrequency
    func hasLifetimeGift() -> Bool
    var subscriptionTier: SubscriptionTier { get }
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

    var subscriptionTier: SubscriptionTier {
        SubscriptionHelper.activeTier
    }

    func subscriptionFrequency() -> SubscriptionFrequency {
        SubscriptionHelper.subscriptionFrequencyValue()
    }

    func hasLifetimeGift() -> Bool {
        SubscriptionHelper.hasLifetimeGift()
    }
}
