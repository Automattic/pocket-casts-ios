import Foundation
import PocketCastsServer

/// Abstraction to return information about the subscriptions
public protocol TracksSubscriptionData {
    func hasActiveSubscription() -> Bool
    func subscriptionPlatform() -> SubscriptionPlatform
    func subscriptionType() -> SubscriptionType
    func subscriptionFrequency() -> SubscriptionFrequency
    func hasLifetimeGift() -> Bool
    var subscriptionTier: SubscriptionTier { get }
}

/// Retrieves Pocket Casts specific data for use in tracks
public struct PocketCastsTracksSubscriptionData: TracksSubscriptionData {
    public init() {}

    public func hasActiveSubscription() -> Bool {
        SubscriptionHelper.hasActiveSubscription()
    }

    public func subscriptionPlatform() -> SubscriptionPlatform {
        SubscriptionHelper.subscriptionPlatform()
    }

    public func subscriptionType() -> SubscriptionType {
        SubscriptionHelper.subscriptionType()
    }

    public var subscriptionTier: SubscriptionTier {
        SubscriptionHelper.activeTier
    }

    public func subscriptionFrequency() -> SubscriptionFrequency {
        SubscriptionHelper.subscriptionFrequencyValue()
    }

    public func hasLifetimeGift() -> Bool {
        SubscriptionHelper.hasLifetimeGift()
    }
}
