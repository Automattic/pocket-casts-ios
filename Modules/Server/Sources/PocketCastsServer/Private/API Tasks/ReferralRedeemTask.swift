import Foundation
import PocketCastsUtils
import SwiftProtobuf

class ReferralRedeemTask: ApiBaseTask, @unchecked Sendable {
    var completion: ((Bool) -> Void)?

    private let code: String

    init(code: String) {
        self.code = code
    }

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())referrals/redeem"

        do {
            var request = Api_ReferralRedemption()
            request.code = code

            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: urlString, token: token, data: data)

            if response == nil {
                FileLog.shared.addMessage("Referral failed to redeem offer \(code) because response is empty")
                completion?(false)
                return
            }

            if httpStatus == ServerConstants.HttpConstants.ok {
                FileLog.shared.addMessage("Referral redeem successfull for code \(code)")
            } else {
                FileLog.shared.addMessage("Referral failed to redeem code \(code), http status \(httpStatus)")
            }
            completion?(httpStatus == ServerConstants.HttpConstants.ok)
        } catch {
            FileLog.shared.addMessage("Failed to serialize Api_ReferralRedemption \(error.localizedDescription) for code \(code)")
            completion?(false)
        }
    }
}
