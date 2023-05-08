import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

struct DeveloperMenu: View {
    var body: some View {
        List {
            Section {
                Button("Corrupt Sync Login Token") {
                    ServerSettings.syncingV2Token = "badToken"
                }

                Button("Force Reload Discover") {
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.chartRegionChanged)
                }

                Button("Unsubscribe from all Podcasts") {
                    let podcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false)

                    for podcast in podcasts {
                        PodcastManager.shared.unsubscribe(podcast: podcast)
                    }
                }
            }

            Section {
                Button("Set to No Plus") {
                    SubscriptionHelper.setSubscriptionPaid(Int(0))
                    SubscriptionHelper.setSubscriptionPlatform(Int(0))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(false)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(Int(0))
                    SubscriptionHelper.setSubscriptionType(Int(0))

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Button("Set to Paid Plus") {
                    SubscriptionHelper.setSubscriptionPaid(Int(1))
                    SubscriptionHelper.setSubscriptionPlatform(Int(1))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(true)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(Int(2))
                    SubscriptionHelper.setSubscriptionType(Int(1))

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                Button("Set to Paid Patron") {
                    SubscriptionHelper.setSubscriptionPaid(Int(1))
                    SubscriptionHelper.setSubscriptionPlatform(Int(1))
                    SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 30.days).timeIntervalSince1970)
                    SubscriptionHelper.setSubscriptionAutoRenewing(true)
                    SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                    SubscriptionHelper.setSubscriptionFrequency(Int(2))
                    SubscriptionHelper.setSubscriptionType(Int(3))

                    NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                    HapticsHelper.triggerSubscribedHaptic()
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Active but Cancelled: Plus") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 3.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(Int(0))
                        SubscriptionHelper.setSubscriptionType(Int(1))

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Expiring in 2 days")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Active but Cancelled: Patron") {
                        SubscriptionHelper.setSubscriptionPaid(Int(1))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: 3.days).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(Int(0))
                        SubscriptionHelper.setSubscriptionType(Int(3))

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Expiring in 2 days")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Cancelled and Expired: Plus") {
                        SubscriptionHelper.setSubscriptionPaid(Int(0))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: (1.days * -1)).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(Int(0))
                        SubscriptionHelper.setSubscriptionType(Int(0))

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Cancelled subscription, but has passed expiration date")
                        .font(Font.footnote)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Button("Set to Cancelled and Expired: Patron") {
                        SubscriptionHelper.setSubscriptionPaid(Int(0))
                        SubscriptionHelper.setSubscriptionPlatform(Int(1))
                        SubscriptionHelper.setSubscriptionExpiryDate(Date(timeIntervalSinceNow: (1.days * -1)).timeIntervalSince1970)
                        SubscriptionHelper.setSubscriptionAutoRenewing(false)
                        SubscriptionHelper.setSubscriptionGiftDays(Int(0))
                        SubscriptionHelper.setSubscriptionFrequency(Int(0))
                        SubscriptionHelper.setSubscriptionType(Int(3))

                        NotificationCenter.postOnMainThread(notification: ServerNotifications.subscriptionStatusChanged)
                        HapticsHelper.triggerSubscribedHaptic()
                    }
                    Text("Cancelled subscription, but has passed expiration date")
                        .font(Font.footnote)
                }

            } header: {
                Text("Subscription Testing")
            } footer: {
                Text("⚠️ Temporary items only, the changes will only be active until the next server sync.")
            }
        }
    }
}

struct DeveloperMenu_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMenu()
    }
}
