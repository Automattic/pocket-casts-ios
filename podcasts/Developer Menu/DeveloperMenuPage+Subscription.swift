import Foundation
import PocketCastsServer

extension DeveloperMenuPage {
    static var subscription: DeveloperMenuPage {
        DeveloperMenuPage(title: "Subscription", systemImage: "creditcard", sections: [
            DeveloperMenuSection(title: "Active", footer: "Temporary: the changes are only active until the next server sync.", items: [
                .action("Set to No Plus") {
                    ServerSettings.setIapUnverifiedPurchaseReceiptDate(nil)
                    SubscriptionPreset(isPaid: false, platform: .none, expiresIn: 30.days, type: .none, tier: .none).apply()
                },
                .action("Set to Paid Plus") {
                    SubscriptionPreset(expiresIn: 30.days, isAutoRenewing: true, frequency: .monthly, tier: .plus).apply()
                },
                .action("Set to Paid Patron") {
                    SubscriptionPreset(expiresIn: 30.days, isAutoRenewing: true, frequency: .monthly, tier: .patron).apply()
                }
            ]),
            DeveloperMenuSection(title: "Gift", items: [
                .action("Set to 150 Gift Days") {
                    SubscriptionPreset(platform: .gift, expiresIn: 150.days, giftDays: 150, tier: .plus).apply()
                },
                .action("Set to 150 Gift Days Expiring in 1 Day") {
                    SubscriptionPreset(platform: .gift, expiresIn: 1.days, giftDays: 150, tier: .plus).apply()
                },
                .action("Set to 150 Gift Days Expiring in 30 Days") {
                    SubscriptionPreset(platform: .gift, expiresIn: 30.days, giftDays: 150, tier: .plus).apply()
                },
                .action("Set to Lifetime") {
                    SubscriptionPreset(platform: .gift, expiresIn: 11 * 365.days, giftDays: 11 * 365, tier: .plus).apply()
                }
            ]),
            DeveloperMenuSection(title: "Cancelled", items: [
                .action("Set to Active but Cancelled: Plus", subtitle: "Expires in 3 days") {
                    SubscriptionPreset(expiresIn: 3.days, tier: .plus).apply()
                },
                .action("Set to Active but Cancelled: Patron", subtitle: "Expires in 3 days") {
                    SubscriptionPreset(expiresIn: 3.days, tier: .patron).apply()
                },
                .action("Set to Cancelled and Expired: Plus", subtitle: "Expired yesterday") {
                    SubscriptionPreset(isPaid: false, expiresIn: -1.days, tier: .plus).apply()
                },
                .action("Set to Cancelled and Expired: Patron", subtitle: "Expired yesterday") {
                    SubscriptionPreset(isPaid: false, expiresIn: -1.days, tier: .patron).apply()
                }
            ])
        ])
    }
}

private struct SubscriptionPreset {
    var isPaid = true
    var platform: SubscriptionPlatform = .iOS
    let expiresIn: TimeInterval
    var isAutoRenewing = false
    var giftDays = 0
    var frequency: SubscriptionFrequency = .none
    var type: SubscriptionType = .plus
    let tier: SubscriptionTier

    func apply() {
        SubscriptionHelper.setSubscriptionPaid(isPaid ? 1 : 0)
        SubscriptionHelper.setSubscriptionPlatform(platform.rawValue)
        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: expiresIn).timeIntervalSince1970)
        SubscriptionHelper.setSubscriptionAutoRenewing(isAutoRenewing)
        SubscriptionHelper.setSubscriptionGiftDays(giftDays)
        SubscriptionHelper.setSubscriptionFrequency(frequency.rawValue)
        SubscriptionHelper.setSubscriptionType(type.rawValue)
        SubscriptionHelper.subscriptionTier = tier

        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
        HapticsHelper.triggerSubscribedHaptic()
    }
}
