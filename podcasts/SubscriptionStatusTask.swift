import DataModel
import Foundation
import SwiftProtobuf
import Utils

class SubscriptionStatusTask: ApiBaseTask {
    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "subscription/status"
        do {
            let (response, httpStatus) = getToServer(url: url, token: token)

            guard let responseData = response, httpStatus?.statusCode == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("Subscription status failed \(httpStatus?.statusCode ?? -1)")
                return
            }
            do {
                let status = try Api_SubscriptionsStatusResponse(serializedData: responseData)
                let originalSubscriptionStatus = SubscriptionHelper.hasActiveSubscription()
                Settings.setSubscriptionPaid(Int(status.paid))
                Settings.setSubscriptionPlatform(Int(status.platform))
                Settings.setSubscriptionExpiryDate(Int(status.expiryDate.timeIntervalSince1970))
                Settings.setSubscriptionAutoRenewing(status.autoRenewing)
                Settings.setSubscriptionGiftDays(Int(status.giftDays))
                Settings.setSubscriptionFrequency(Int(status.frequency))
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.subscriptionStatusChanged)
                let expiryDate = SubscriptionHelper.subscriptionRenewalDate()
                FileLog.shared.addMessage("Received subscription status paid : \(status.paid), platform : \(status.platform), frequency : \(status.frequency), giftDays : \(status.giftDays), expiryDate :  \(DateFormatHelper.sharedHelper.longLocalizedFormat(expiryDate))")

                if originalSubscriptionStatus, !SubscriptionHelper.hasActiveSubscription() {
                    UserEpisodeManager.cleanupCloudOnlyFiles()
                }
            }
        } catch {
            FileLog.shared.addMessage("Protobuf Encoding failed")
        }
    }
}
