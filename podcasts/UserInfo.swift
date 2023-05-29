import Foundation
import PocketCastsDataModel
import PocketCastsServer

struct UserInfo {
    struct Profile {
        let isLoggedIn: Bool
        let displayName: String?
        let email: String?

        init(isLoggedIn: Bool = SyncManager.isUserLoggedIn(), email: String? = ServerSettings.syncingEmail(), displayName: String? = nil) {
            self.isLoggedIn = isLoggedIn
            self.email = isLoggedIn ? email : nil
            self.displayName = isLoggedIn ? displayName : nil // Placeholder, Not available yet
        }
    }

    struct Subscription {
        let tier: SubscriptionTier
        let expirationProgress: Double
        let expirationDate: Date?

        /// Returns nil if there is no subscription info to return
        init?(loggedIn: Bool = SyncManager.isUserLoggedIn()) {
            let hasSubscription = SubscriptionHelper.hasActiveSubscription()
            let tier = SubscriptionHelper.activeTier

            guard loggedIn, hasSubscription, tier != .none else {
                return nil
            }

            self.tier = tier

            let maxDisplayTime = Constants.Limits.maxSubscriptionExpirySeconds

            expirationDate = hasSubscription ? SubscriptionHelper.subscriptionRenewalDate() : nil

            // Don't show the expiration label if we're outside of the max days
            guard let expiration = SubscriptionHelper.timeToSubscriptionExpiry(), expiration <= maxDisplayTime else {
                expirationProgress = hasSubscription ? 1 : 0
                return
            }

            expirationProgress = (expiration / maxDisplayTime).clamped(to: 0..<1)
        }

        func isExpiring(_ type: SubscriptionTier) -> Bool {
            self.tier == type && expirationProgress < 1
        }
    }

    struct Stats {
        /// The total number of podcasts the user is subscribed to
        let podcastCount: Int

        /// The total time the user has listened to podcasts
        let listeningTime: Stat

        /// The total time the user has saved from playback effects
        let savedTime: Stat

        init() {
            podcastCount = DataManager.sharedManager.podcastCount()
            listeningTime = .init(seconds: StatsManager.shared.totalListeningTimeInclusive())
            savedTime = .init(seconds: StatsManager.shared.totalSavedTime())
        }

        struct Stat {
            let seconds: TimeInterval
            let formatValues: Double.TimeFormatValueType

            init(seconds: TimeInterval) {
                self.seconds = seconds
                formatValues = seconds.timeFormatValues
            }
        }
    }
}
