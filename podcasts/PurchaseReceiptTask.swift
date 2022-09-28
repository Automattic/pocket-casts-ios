import DataModel
import SwiftProtobuf
import UIKit
import Utils

class PurchaseReceiptTask: ApiBaseTask {
    var completion: ((Bool) -> Void)?
    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "subscription/purchase/ios"

        // Load the receipt into a Data object
        guard
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: receiptUrl)
        else {
            FileLog.shared.addMessage("NO RECEIPT in app bundle\n")
            // TODO: should we do something here ? or maybe pass the receipt into this function
            // so we can do something if the receipt doesn't exist
            return
        }

        let receiptString = receiptData.base64EncodedString()
        var updateRequest = Api_SubscriptionsPurchaseAppleRequest()
        updateRequest.receipt = receiptString

        do {
            let data = try updateRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("Purchase Receipt send failed \(httpStatus)")
                completion?(false)
                if let purchaseDate = Settings.iapUnverifiedPurchaseReceiptDate(), purchaseDate.timeIntervalSinceNow > 7.days {
                    Settings.setIapUnverifiedPurchaseReceiptDate(nil)
                    let dateString = DateFormatHelper.sharedHelper.jsonFormat(Settings.iapUnverifiedPurchaseReceiptDate())
                    FileLog.shared.addMessage("Purchase Receipt Send has been failing for 7 days, allow user to be downgraded (last receipt date is \(dateString)")
                }
                return
            }
            do {
                let status = try Api_SubscriptionsStatusResponse(serializedData: responseData)
                Settings.setSubscriptionPaid(Int(status.paid))
                Settings.setSubscriptionPlatform(Int(status.platform))
                Settings.setSubscriptionExpiryDate(Int(status.expiryDate.timeIntervalSince1970))
                Settings.setSubscriptionAutoRenewing(status.autoRenewing)
                Settings.setSubscriptionGiftDays(Int(status.giftDays))
                Settings.setIapUnverifiedPurchaseReceiptDate(nil)
                completion?(true)
                NotificationCenter.postOnMainThread(notification: Constants.Notifications.subscriptionStatusChanged)
                FileLog.shared.addMessage("Receipt sent to server, got subscription status \n \(status)")
            } catch {
                FileLog.shared.addMessage("Purchase receipt status failed")
            }
        } catch {
            FileLog.shared.addMessage("Protobuf Encoding failed")
        }
    }
}
