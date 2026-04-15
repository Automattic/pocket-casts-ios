import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct WinbackOfferInfo: Codable {
    public let offer: String
    public let platform: Int
    public let code: String
    public let details: ReferralOfferDetail?
    public var offerPrice: String?
}

class WinbackOfferTask: ApiBaseTask, @unchecked Sendable {
    var completion: ((WinbackOfferInfo?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())referrals/winback_offers?platform=ios"

        do {
            let (data, httpResponse) = getToServer(url: urlString, token: token)
            guard let responseData = data,
                  httpResponse?.statusCode == ServerConstants.HttpConstants.ok
            else {
                FileLog.shared.addMessage("Failed to get winback offer - server returned \(httpResponse?.statusCode ?? -1)")
                completion?(nil)
                return
            }
            let validationResponse = try Api_WinbackResponse(serializedData: responseData)
            let details = try? JSONDecoder().decode(ReferralOfferDetail.self, from: validationResponse.details.data(using: .utf8)!)
            let winbackOffer = WinbackOfferInfo(
                offer: validationResponse.offer,
                platform: Int(validationResponse.platform),
                code: validationResponse.code,
                details: details
            )
            completion?(winbackOffer)
        } catch {
            FileLog.shared.addMessage("Failed to parse Api_ReferralValidationResponse \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
