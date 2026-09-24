import Foundation
import PocketCastsServer

extension DeveloperMenuSection {
    static var subscription: DeveloperMenuSection {
        DeveloperMenuSection(title: "Subscription", footer: "Temporary: the changes are only active until the next server sync.", items: [
            .menu("Set to Active", items: [
                .action("No Plus") {
                    ServerSettings.setIapUnverifiedPurchaseReceiptDate(nil)
                    SubscriptionPreset(isPaid: false, platform: .none, expiresIn: 30.days, type: .none, tier: .none).apply()
                },
                .action("Paid Plus") {
                    SubscriptionPreset(expiresIn: 30.days, isAutoRenewing: true, frequency: .monthly, tier: .plus).apply()
                },
                .action("Paid Patron") {
                    SubscriptionPreset(expiresIn: 30.days, isAutoRenewing: true, frequency: .monthly, tier: .patron).apply()
                }
            ]),
            .menu("Set to Gift", items: [
                .action("150 Gift Days") {
                    SubscriptionPreset(platform: .gift, expiresIn: 150.days, giftDays: 150, tier: .plus).apply()
                },
                .action("150 Gift Days", subtitle: "Expires in 1 day") {
                    SubscriptionPreset(platform: .gift, expiresIn: 1.days, giftDays: 150, tier: .plus).apply()
                },
                .action("150 Gift Days", subtitle: "Expires in 30 days") {
                    SubscriptionPreset(platform: .gift, expiresIn: 30.days, giftDays: 150, tier: .plus).apply()
                },
                .action("Lifetime") {
                    SubscriptionPreset(platform: .gift, expiresIn: 11 * 365.days, giftDays: 11 * 365, tier: .plus).apply()
                }
            ]),
            .menu("Set to Cancelled", sections: [
                DeveloperMenuSection(title: "Active, expires in 3 days", items: [
                    .action("Plus") {
                        SubscriptionPreset(expiresIn: 3.days, tier: .plus).apply()
                    },
                    .action("Patron") {
                        SubscriptionPreset(expiresIn: 3.days, tier: .patron).apply()
                    }
                ]),
                DeveloperMenuSection(title: "Expired yesterday", items: [
                    .action("Plus") {
                        SubscriptionPreset(isPaid: false, expiresIn: -1.days, tier: .plus).apply()
                    },
                    .action("Patron") {
                        SubscriptionPreset(isPaid: false, expiresIn: -1.days, tier: .patron).apply()
                    }
                ])
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
