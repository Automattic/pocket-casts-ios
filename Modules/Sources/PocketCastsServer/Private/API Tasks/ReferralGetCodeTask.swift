import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct ReferralCode: Codable {
    public let code: String
    public let url: String
}

class ReferralGetCodeTask: ApiBaseTask, @unchecked Sendable {
    var completion: ((ReferralCode?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())referrals/code"

        do {
            let (data, httpResponse) = getToServer(url: urlString, token: token)

            guard let responseData = data,
                  httpResponse?.statusCode == ServerConstants.HttpConstants.ok
            else {
                FileLog.shared.addMessage("Failed to get referral code - server returned \(httpResponse?.statusCode ?? -1), firing refresh failed")
                completion?(nil)
                return
            }
            let apiCode = try Api_ReferralCode(serializedBytes: responseData)
            completion?(ReferralCode(code: apiCode.code, url: apiCode.url))
        } catch {
            FileLog.shared.addMessage("Failed to parse  Api_GetRererralCodeRequest \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
