import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct ReferralValidate: Codable {
    public let offer: String
}

class ReferralValidateTask: ApiBaseTask, @unchecked Sendable {

    let code: String
    var completion: ((ReferralValidate?) -> Void)?

    init(code: String) {
        self.code = code
        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())referrals/validate?code=\(code)"

        do {
            let (data, httpResponse) = getToServer(url: urlString, token: token)

            guard let responseData = data,
                  httpResponse?.statusCode == ServerConstants.HttpConstants.ok
            else {
                FileLog.shared.addMessage("Failed to validate referral code - server returned \(httpResponse?.statusCode ?? -1)")
                completion?(nil)
                return
            }
            let apiCode = try Api_ReferralValidationResponse(serializedBytes: responseData)
            completion?(ReferralValidate(offer: apiCode.offer))
        } catch {
            FileLog.shared.addMessage("Failed to parse  Api_ReferralValidationResponse \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
