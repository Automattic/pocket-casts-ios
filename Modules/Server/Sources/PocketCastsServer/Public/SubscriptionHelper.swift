import UIKit
import PocketCastsUtils

open class SubscriptionHelper: NSObject {
    public static let shared = SubscriptionHelper()

    /// Returns the users active subscription tier or .none if they don't currently have one
    open var activeTier: SubscriptionTier {
        // Right now we're just returning the class var to maintain compatibility. In the future this will change.
        Self.activeTier
    }

    /// Returns the users active subscription type or .none if they don't currently have one
    public static var activeSubscriptionType: SubscriptionType {
        hasActiveSubscription() ? subscriptionType() : .none
    }

    /// Returns the users active subscription tier or .none if they don't currently have one
    public static var activeTier: SubscriptionTier {
        guard hasActiveSubscription() else {
            return .none
        }

        let tier = subscriptionTier

        // Fallback handling
        // If the server isn't returning the subscription tier yet then the tier will be none
        // If the user has an active subscription, and the tier is none, and their subscription type is plus
        // Then fallback to returning plus as the tier
        //
        // This should be removed after the Patron server changes have been pushed to production
        guard tier == .none, subscriptionType() == .plus else {
            return tier
        }

        return .plus
    }

    /// The users subscription tier, or .none if there isn't one available
    public class var subscriptionTier: SubscriptionTier {
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: ServerConstants.UserDefaults.subscriptionTier)
        }

        get {
            UserDefaults.standard.string(forKey: ServerConstants.UserDefaults.subscriptionTier).flatMap {
                SubscriptionTier(rawValue: $0)
            } ?? .none
        }
    }

    public class func hasActiveSubscription() -> Bool {
        let status = UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.subscriptionPaid)
        return status
    }

    public class func hasRenewingSubscription() -> Bool {
        let status = UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.subscriptionAutoRenewing)
        return status
    }

    public class func subscriptionGiftDays() -> Int {
        let days = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionGiftDays)
        return days
    }

    public class func subscriptionPlatform() -> SubscriptionPlatform {
        let intValue = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionPlatform)

        return SubscriptionPlatform(rawValue: intValue) ?? .none
    }

    public class func subscriptionRenewalDate() -> Date? {
        let renewalTimeInterval = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionExpiryDate)
        let renewalDate = Date(timeIntervalSince1970: TimeInterval(renewalTimeInterval))
        return renewalDate
    }

    public class func timeToSubscriptionExpiry() -> TimeInterval? {
        if !hasRenewingSubscription() {
            let renewalTimeInterval = UserDefaults.standard.double(forKey: ServerConstants.UserDefaults.subscriptionExpiryDate)
            if renewalTimeInterval == 0 { return nil } // we can't calculate an offset to an non-existent time

            let expiryDate = Date(timeIntervalSince1970: renewalTimeInterval)
            let expiryTime = expiryDate.timeIntervalSinceNow
            return expiryTime
        }
        return nil
    }

    public class func hasLifetimeGift() -> Bool {
        guard SubscriptionHelper.subscriptionPlatform() == .gift else { return false }
        let days = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionGiftDays)
        let tenYearsInDays = 10 * 365
        return days > tenYearsInDays
    }

    public class func subscriptionFrequencyValue() -> SubscriptionFrequency {
        let intValue = UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionFrequency)

        return SubscriptionFrequency(rawValue: intValue) ?? .none
    }

    // MARK: - Set Subscription status

    public class func setSubscriptionPaid(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionPaid)
    }

    public class func setSubscriptionPlatform(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionPlatform)
    }

    public class func setSubscriptionAutoRenewing(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionAutoRenewing)
    }

    public class func setSubscriptionExpiryDate(_ value: TimeInterval) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionExpiryDate)
    }

    public class func setSubscriptionGiftDays(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionGiftDays)
    }

    public class func setSubscriptionFrequency(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionFrequency)
    }

    public class func setSubscriptionGiftAcknowledgement(_ value: Bool) {
        if FeatureFlag.settingsSync.enabled {
            SettingsStore.appSettings.freeGiftAcknowledgement = value
        }
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgement)
        UserDefaults.standard.set(true, forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgementNeedsSyncKey)
    }

    public class func subscriptionGiftAcknowledgement() -> Bool {
        if FeatureFlag.settingsSync.enabled {
            return SettingsStore.appSettings.freeGiftAcknowledgement
        } else {
            return UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgement)
        }
    }

    public class func subscriptionGiftAcknowledgementNeedsSyncing() -> Bool {
        UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgementNeedsSyncKey)
    }

    public class func subscriptionGiftAcknowledgementSynced() {
        UserDefaults.standard.set(false, forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgementNeedsSyncKey)
    }

    public class func setSubscriptionType(_ value: Int) {
        UserDefaults.standard.set(value, forKey: ServerConstants.UserDefaults.subscriptionType)
    }

    public class func subscriptionType() -> SubscriptionType {
        SubscriptionType(rawValue: UserDefaults.standard.integer(forKey: ServerConstants.UserDefaults.subscriptionType)) ?? SubscriptionType.none
    }

    public class func setSubscriptionPodcasts(_ value: [PodcastSubscription]) {
        do {
            let data = try PropertyListEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: ServerConstants.UserDefaults.subscriptionPodcasts)
        } catch {
            print("failed to encode subscription podcasts")
        }
    }

    public class func subscriptionPodcasts() -> [PodcastSubscription]? {
        guard let data = UserDefaults.standard.data(forKey: ServerConstants.UserDefaults.subscriptionPodcasts), let subscriptions = try? PropertyListDecoder().decode([PodcastSubscription].self, from: data) else {
            return nil
        }
        return subscriptions
    }

    public class func subscriptionForPodcast(uuid: String) -> PodcastSubscription? {
        guard let allSubscriptions = subscriptionPodcasts() else { return nil }

        return allSubscriptions.first { podcastSubscription -> Bool in
            podcastSubscription.uuid == uuid
        }
    }

    public class func numActiveSubscriptionBundles() -> Int {
        guard let bundles = subscriptionBundles() else {
            return 0
        }
        return bundles.count
    }

    public class func subscriptionBundles() -> [BundleSubscription]? {
        guard let subscriptions = subscriptionPodcasts() else { return nil }
        var bundles = [BundleSubscription]()

        for subscription in subscriptions {
            if let existingIndex = bundles.firstIndex(where: { $0.bundleUuid == subscription.bundleUuid }) {
                var existingBundle = bundles[existingIndex]
                bundles.remove(at: existingIndex)
                existingBundle.podcasts.append(subscription)
                bundles.insert(existingBundle, at: existingIndex)
            } else {
                let newBundle = BundleSubscription(bundleUuid: subscription.bundleUuid, podcasts: [subscription])
                bundles.append(newBundle)
            }
        }
        return bundles
    }

    public class func bundleSubscriptionForPodcast(podcastUuid: String) -> BundleSubscription? {
        guard let bundles = subscriptionBundles() else {
            return nil
        }
        for bundle in bundles {
            if bundle.podcasts.first(where: { $0.uuid == podcastUuid }) != nil {
                return bundle
            }
        }
        return nil
    }
}
