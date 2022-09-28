import DataModel
import SwiftProtobuf
import UIKit
import Utils

class ValidatePromoCodeTask {
    class func validatePromoCode(promoCode: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: Server.Urls.api + "subscription/promo/validate") else {
            return
        }

        var codeToValidate = Api_PromotionCode()
        codeToValidate.code = promoCode

        do {
            let data = try codeToValidate.serializedData()
            guard let request = ServerHelper.createProtoRequest(url: url, data: data) else {
                completion(false, nil)
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in

                guard let httpResponse = response as? HTTPURLResponse, let responseData = data, error == nil else {
                    completion(false, nil)
                    return
                }
                print("Server response is \(httpResponse.statusCode)")
                if httpResponse.statusCode == Server.HttpConstants.ok {
                    do {
                        let promotion = try Api_Promotion(serializedData: responseData)
                        completion(true, promotion.description_p)

                        FileLog.shared.addMessage("Validate promo code response \n \(httpResponse.statusCode)")
                        return
                    } catch {
                        FileLog.shared.addMessage("Validate promo code failed")
                    }
                } else {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: String], let errorMessage = json["errorMessage"] {
                            FileLog.shared.addMessage("Validate promo code response \n \(httpResponse.statusCode), error ")
                            completion(false, errorMessage)
                            return
                        }
                    } catch {
                        FileLog.shared.addMessage("Validate promo code failed")
                    }
                }
                completion(false, nil)

            }.resume()
        } catch {
            FileLog.shared.addMessage("Validate Promo Code Request Protobuf Encoding failed")
        }
    }
}
