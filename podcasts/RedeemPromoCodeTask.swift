import DataModel
import SwiftProtobuf
import UIKit
import Utils

class RedeemPromoCodeTask: ApiBaseTask {
    var completion: ((Int, String) -> Void)?
    private var promoCode: String

    init(promoCode: String) {
        self.promoCode = promoCode
        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "subscription/promo/redeem"

        var codeToValidate = Api_PromotionCode()
        codeToValidate.code = promoCode

        do {
            let data = try codeToValidate.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response else {
                completion?(httpStatus, "Something went wrong")
                return
            }

            do {
                if httpStatus == Server.HttpConstants.ok {
                    let promotion = try Api_Promotion(serializedData: responseData)
                    completion?(httpStatus, promotion.description_p)
                    FileLog.shared.addMessage("Redeem promo code response \n \(httpStatus)")
                } else {
                    if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: String], let errorMessage = json["errorMessage"] {
                        FileLog.shared.addMessage("Redeem promo code response \n \(httpStatus), error ")
                        completion?(httpStatus, errorMessage)
                        return
                    }
                }
            } catch {
                FileLog.shared.addMessage("Redeem promo code failed")
                completion?(httpStatus, "Something went wrong")
                return
            }
        } catch {
            FileLog.shared.addMessage("Redeem promo code Protobuf Encoding failed")
            completion?(0, "Something went wrong")
            return
        }
    }
}
