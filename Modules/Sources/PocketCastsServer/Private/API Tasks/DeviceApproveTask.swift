import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct DeviceApproveResult: Decodable {
    public let success: Bool
    public let message: String
    public let messageId: String
}

class DeviceApproveTask: ApiBaseTask, @unchecked Sendable {

    let userCode: String
    let approve: Bool

    init(userCode: String, approve: Bool) {
        self.userCode = userCode
        self.approve = approve
    }
    var completion: ((Result<DeviceApproveResult, Error>) -> Void)?

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())device/approve"

        do {
            var request = Api_DeviceApproveRequest()
            request.userCode = userCode
            request.deny = !approve

            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: urlString, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(.failure(APIError.UNKNOWN))
                return
            }
            let changeResponse = try Api_UserChangeResponse(serializedBytes: responseData)

            completion?(.success(DeviceApproveResult(success: changeResponse.success.value, message: changeResponse.message, messageId: changeResponse.messageID)))
            FileLog.shared.addMessage("API device approved response \(changeResponse)")
        } catch {
            FileLog.shared.addMessage("Failed to approve device \(error.localizedDescription)")
            completion?(.failure(APIError.UNKNOWN))
        }
    }
}
