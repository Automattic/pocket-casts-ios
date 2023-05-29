import SwiftUI
import PocketCastsServer

/// View model for the header view that appears on the Profile tab view
class AccountHeaderViewModel: ProfileDataViewModel {
    @Published var viewState: ViewState = .freeAccount

    override func update() {
        super.update()

        // If there is no active subscription, then we're a free account
        guard SubscriptionHelper.hasActiveSubscription() else {
            viewState = .freeAccount
            return
        }

        // Calculate the view state
        // Original logic: https://github.com/Automattic/pocket-casts-ios/blob/ab03b1bb9660ca2946c437a6d29d76905810538c/podcasts/AccountViewController.swift#L195

        let expirationDate = SubscriptionHelper.subscriptionRenewalDate()
        let frequency = SubscriptionHelper.subscriptionFrequencyValue()
        let type = SubscriptionHelper.subscriptionType()
        let giftDays = SubscriptionHelper.subscriptionGiftDays()

        let hasLifeTime = SubscriptionHelper.hasLifetimeGift()
        let hasRenewing = SubscriptionHelper.hasRenewingSubscription()
        let platform = SubscriptionHelper.subscriptionPlatform()

        switch(hasRenewing, platform, hasLifeTime) {
        case (true, _, _): // Has a renewing subscription
            viewState = .activeSubscription(type, frequency, expirationDate)
        case (false, .gift, true): // Lifetime plus subscription
            viewState = .lifetime
        case (false, .gift, false): // Gift days (free trial)
            viewState = .freeTrial(Double(giftDays).days)
        default: // Anything else should be a cancelled but not expired sub
            viewState = .paymentCancelled(type, frequency)
        }
    }

    enum ViewState {
        case freeAccount
        case lifetime
        case activeSubscription(SubscriptionType, SubscriptionFrequency, Date?)
        case freeTrial(TimeInterval)
        case paymentCancelled(SubscriptionType, SubscriptionFrequency)
    }
}
