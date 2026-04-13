import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf
import UIKit

class RedeemPromoCodeTask: ApiBaseTask {
    var completion: ((Int, String?, APIError?) -> Void)?
    private var promoCode: String

    init(promoCode: String) {
        self.promoCode = promoCode
        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "subscription/promo/redeem"

        var codeToValidate = Api_PromotionCode()
        codeToValidate.code = promoCode

        do {
            let data = try codeToValidate.serializedData()
            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response else {
                completion?(httpStatus, nil, APIError.UNKNOWN)
                return
            }

            do {
                if httpStatus == ServerConstants.HttpConstants.ok {
                    let promotion = try Api_Promotion(serializedData: responseData)
                    completion?(httpStatus, promotion.description_p, nil)
                    FileLog.shared.addMessage("Redeem promo code response \n \(httpStatus)")
                } else if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: String], let errorMessageId = json["errorMessageId"] {
                    FileLog.shared.addMessage("Redeem promo code response \n \(httpStatus), error ")
                    let error = APIError(rawValue: errorMessageId) ?? .UNKNOWN
                    completion?(httpStatus, nil, error)
                }
            } catch {
                FileLog.shared.addMessage("Redeem promo code failed \(error.localizedDescription)")
                completion?(httpStatus, nil, APIError.UNKNOWN)
            }
        } catch {
            FileLog.shared.addMessage("Redeem promo code Protobuf Encoding failed \(error.localizedDescription)")
            completion?(0, nil, APIError.UNKNOWN)
        }
    }
}
