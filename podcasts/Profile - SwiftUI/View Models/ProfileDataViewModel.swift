import Foundation
import Combine
import PocketCastsServer
import PocketCastsDataModel

/// Represents a view that will display information about the users profile such as email, subscription status, and stats
class ProfileDataViewModel: ObservableObject {

    // Allow UIKit to update to view size changes
    private(set) var contentSize: CGSize? = nil
    var viewContentSizeChanged: (() -> Void)? = nil

    /// The user profile information such as logged in, email, etc
    var profile: Profile = .init()

    /// The users subscription information, will be nil if there is no active subscription
    var subscription: Subscription?

    /// Listening Stats
    var stats: Stats = .init()

    private var notifications = Set<AnyCancellable>()

    init() {
        update()

        // Listen for the refresh event to update the view
        NotificationCenter.default
            .publisher(for: ServerNotifications.podcastsRefreshed)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] _ in self?.update() })
            .store(in: &notifications)
    }

    /// Refresh the store data
    func update() {
        profile = .init()
        subscription = .init(loggedIn: profile.isLoggedIn)
        stats = .init()

        objectWillChange.send()
    }

    func contentSizeChanged(_ size: CGSize) {
        contentSize = size
        viewContentSizeChanged?()
    }

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
        let type: SubscriptionType
        let expirationProgress: Double
        let expirationDate: Date?

        /// Returns nil if there is no subscription info to return
        init?(loggedIn: Bool) {
            let hasSubscription = SubscriptionHelper.hasActiveSubscription()
            let type = SubscriptionHelper.subscriptionType()

            guard loggedIn, hasSubscription, type != .none else {
                return nil
            }

            self.type = type

            let maxDisplayTime = Constants.Limits.maxSubscriptionExpirySeconds

            // Don't show the expiration label if we're outside of the max days
            guard let expiration = SubscriptionHelper.timeToSubscriptionExpiry(), expiration <= maxDisplayTime else {
                expirationDate = nil
                expirationProgress = hasSubscription ? 1 : 0
                return
            }

            expirationProgress = (expiration / maxDisplayTime).clamped(to: 0..<1)
            expirationDate = hasSubscription ? SubscriptionHelper.subscriptionRenewalDate() : nil
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
