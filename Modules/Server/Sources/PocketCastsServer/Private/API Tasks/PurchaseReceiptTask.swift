import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf
import UIKit

class PurchaseReceiptTask: ApiBaseTask {
    var completion: ((Bool) -> Void)?
    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "subscription/purchase/ios"

        // Load the receipt into a Data object
        guard
            let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: receiptUrl)
        else {
            FileLog.shared.addMessage("Purchase Receipt send failed because there is NO RECEIPT in the app bundle.\n")
            completion?(false)
            return
        }

        FileLog.shared.addMessage("PurchaseReceiptTask: Receipt URL: \(receiptUrl)")
        FileLog.shared.addMessage("PurchaseReceiptTask: iapUnverifiedPurchaseReceiptDate: \(String(describing: ServerSettings.iapUnverifiedPurchaseReceiptDate()))")

        let receiptString = receiptData.base64EncodedString()
        var updateRequest = Api_SubscriptionsPurchaseAppleRequest()
        updateRequest.receipt = receiptString

        do {
            let data = try updateRequest.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("Purchase Receipt send failed \(httpStatus)")
                completion?(false)
                if let purchaseDate = ServerSettings.iapUnverifiedPurchaseReceiptDate(), purchaseDate.timeIntervalSinceNow > 7.days {
                    ServerSettings.setIapUnverifiedPurchaseReceiptDate(nil)
                    let dateString = DateFormatHelper.sharedHelper.jsonFormat(ServerSettings.iapUnverifiedPurchaseReceiptDate())
                    FileLog.shared.addMessage("Purchase Receipt Send has been failing for 7 days, allow user to be downgraded (last receipt date is \(dateString)")
                }
                return
            }
            do {
                let status = try Api_SubscriptionsStatusResponse(serializedData: responseData)
                SubscriptionHelper.setSubscriptionPaid(Int(status.paid))
                SubscriptionHelper.setSubscriptionPlatform(Int(status.platform))
                SubscriptionHelper.setSubscriptionExpiryDate(status.expiryDate.timeIntervalSince1970)
                SubscriptionHelper.setSubscriptionAutoRenewing(status.autoRenewing)
                SubscriptionHelper.setSubscriptionGiftDays(Int(status.giftDays))
                ServerSettings.setIapUnverifiedPurchaseReceiptDate(nil)
                completion?(true)
                NotificationCenter.default.post(name: ServerNotifications.subscriptionStatusChanged, object: nil)
                FileLog.shared.addMessage("Receipt sent to server, got subscription status \n \(status)")
            } catch {
                FileLog.shared.addMessage("Purchase receipt status failed \(error.localizedDescription)")
                completion?(false)
            }
        } catch {
            FileLog.shared.addMessage("PurchaseReceiptTask: Protobuf Encoding failed \(error.localizedDescription)")
            completion?(false)
        }
    }
}
