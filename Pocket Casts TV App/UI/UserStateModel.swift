import PocketCastsServer
import PocketCastsUtils
import Combine

@Observable
class UserStateModel {

    private var cancellables: Set<AnyCancellable> = []

    var isPlusUser: Bool = false
    var isLoggedIn: Bool = false
    var usernameEmail: String?
    var expirationDate: Date?
    var frequency: SubscriptionFrequency = .none
    var subscriptionTier: SubscriptionTier = .none
    var platform: SubscriptionPlatform = .iOS
    var subscriptionStatus: SubscriptionStatus = .freeAccount

    var usernameLabel: String {
        let usernameLabel = isLoggedIn ? (usernameEmail ?? "") : L10n.signedOut
        return usernameLabel
    }

    init() {
        refresh()
        setupObservers()
    }

    func refresh() {
        isPlusUser = SubscriptionHelper.hasActiveSubscription()
        isLoggedIn = SyncManager.isUserLoggedIn()
        usernameEmail = ServerSettings.syncingEmail()
        expirationDate = SubscriptionHelper.subscriptionRenewalDate()
        frequency = SubscriptionHelper.subscriptionFrequencyValue()
        subscriptionTier = SubscriptionHelper.activeTier
        platform = SubscriptionHelper.subscriptionPlatform()

        let giftDays = SubscriptionHelper.subscriptionGiftDays()
        let hasLifeTime = SubscriptionHelper.hasLifetimeGift()
        let hasRenewing = SubscriptionHelper.hasRenewingSubscription()
        subscriptionStatus = SubscriptionStatus.make(hasActiveSubscription: isPlusUser, type: subscriptionTier, hasRenewing: hasRenewing, platform: platform, hasLifeTime: hasLifeTime, frequency: frequency, expirationDate: expirationDate, giftDays: giftDays)
    }

    private func setupObservers() {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: ServerNotifications.subscriptionStatusChanged),
            NotificationCenter.default.publisher(for: .userLoginDidChange)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self else {
                return
            }
            refresh()
        }
        .store(in: &cancellables)
    }
}


enum SubscriptionStatus {
    case freeAccount
    case lifetime
    case activeSubscription(SubscriptionTier, SubscriptionFrequency, Date?)
    case freeTrial(TimeInterval)
    case paymentCancelled(SubscriptionTier, SubscriptionFrequency)

    static func make(hasActiveSubscription: Bool, type: SubscriptionTier, hasRenewing: Bool, platform: SubscriptionPlatform, hasLifeTime: Bool, frequency: SubscriptionFrequency, expirationDate: Date?, giftDays: Int) -> SubscriptionStatus {
        guard hasActiveSubscription else {
            return .freeAccount
        }

        switch(hasRenewing, platform, hasLifeTime) {
        case (true, _, _): // Has a renewing subscription
            return .activeSubscription(type, frequency, expirationDate)
        case (false, .gift, true): // Lifetime plus subscription
            return .lifetime
        case (false, .gift, false): // Gift days (free trial)
            return .freeTrial(Double(giftDays).days)
        default: // Anything else should be a cancelled but not expired sub
            return .paymentCancelled(type, frequency)
        }
    }
}
