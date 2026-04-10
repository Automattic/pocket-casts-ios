import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf
import UIKit

public class ValidatePromoCodeTask {
    public class func validatePromoCode(promoCode: String, completion: @escaping (Bool, String?, APIError?) -> Void) {
        guard let url = URL(string: ServerConstants.Urls.api() + "subscription/promo/validate") else {
            return
        }

        var codeToValidate = Api_PromotionCode()
        codeToValidate.code = promoCode

        do {
            let data = try codeToValidate.serializedData()
            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                completion(false, nil, nil)
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in

                guard let httpResponse = response as? HTTPURLResponse, let responseData = data, error == nil else {
                    completion(false, nil, nil)
                    return
                }
                print("Server response is \(httpResponse.statusCode)")
                if httpResponse.statusCode == ServerConstants.HttpConstants.ok {
                    do {
                        let promotion = try Api_Promotion(serializedData: responseData)
                        completion(true, promotion.description_p, nil)

                        FileLog.shared.addMessage("Validate promo code response \n \(httpResponse.statusCode)")
                        return
                    } catch {
                        FileLog.shared.addMessage("Validate promo code failed")
                    }
                } else {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: String], let errorMessageId = json["errorMessageId"] {
                            FileLog.shared.addMessage("Validate promo code response \n \(httpResponse.statusCode), error ")
                            let error = APIError(rawValue: errorMessageId) ?? .UNKNOWN
                            completion(false, nil, error)
                            return
                        }
                    } catch {
                        FileLog.shared.addMessage("Validate promo code failed")
                    }
                }
                completion(false, nil, nil)

            }.resume()
        } catch {
            FileLog.shared.addMessage("Validate Promo Code Request Protobuf Encoding failed")
        }
    }
}
