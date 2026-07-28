import Foundation
import SwiftProtobuf
import PocketCastsUtils

class CancelSubscriptionSurveyTask: ApiBaseTask, @unchecked Sendable {
    var completion: ((Bool) -> Void)?

    private let reason: String
    private let other: String?

    init(reason: String, other: String?) {
        self.reason = reason
        self.other = other
    }

    override func apiTokenAcquired(token: String) {
        do {
            let urlString = "\(ServerConstants.Urls.api())subscription/survey"
            var request = Api_UserSubscriptionSurveyRequest()
            request.reason = reason
            if let other, !other.isEmpty {
                request.other = other
            }

            FileLog.shared.addMessage("Post survey for reason \(reason), other: \(other ?? "nil")")

            let data = try request.serializedData()
            let (response, httpStatus) = postToServer(url: urlString, token: token, data: data)
            if response == nil {
                FileLog.shared.addMessage("Failed to post survey. Response nil.")
                completion?(false)
                return
            }

            if httpStatus == ServerConstants.HttpConstants.ok {
                FileLog.shared.addMessage("Post survey success.")
            } else {
                FileLog.shared.addMessage("Failed to post survey., http status \(httpStatus)")
            }
            completion?(httpStatus == ServerConstants.HttpConstants.ok)
        } catch {
            FileLog.shared.addMessage("Failed to serialize Api_UserSubscriptionSurveyRequest \(error.localizedDescription)")
            completion?(false)
        }
    }
}
