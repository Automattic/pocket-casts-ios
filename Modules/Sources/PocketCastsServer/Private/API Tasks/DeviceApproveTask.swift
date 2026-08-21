import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct DeviceApproveResult {
    public let success: Bool
}

class DeviceApproveTask: ApiBaseTask, @unchecked Sendable {

    let userCode: String
    let approve: Bool

    init(userCode: String, approve: Bool) {
        self.userCode = userCode
        self.approve = approve
    }
    var completion: ((Result<DeviceApproveResult, Error>) -> Void)?

    override func apiTokenAcquired(token: String) async {
        let urlString = "\(ServerConstants.Urls.api())device/approve"

        do {
            var request = Api_DeviceApproveRequest()
            request.userCode = userCode
            request.deny = !approve

            let data = try request.serializedData()

            let (responseData, httpStatus) = await postToServer(url: urlString, token: token, data: data)

            guard let responseData, httpStatus == ServerConstants.HttpConstants.ok else {
                if let errorResponse = ApiServerHandler.extractErrorResponse(data: responseData, response: nil, error: nil) {
                    FileLog.shared.addMessage("Unable to approve device, status code: \(httpStatus), server error: \(errorResponse.rawValue)")
                    completion?(.failure(errorResponse))
                    return
                }
                completion?(httpStatus == ServerConstants.HttpConstants.serverError ? .failure(APIError.NO_CONNECTION) : .failure(APIError.UNKNOWN))
                return
            }
            let changeResponse = try Api_DeviceApproveResponse(serializedBytes: responseData)

            completion?(.success(DeviceApproveResult(success: true)))
            FileLog.shared.addMessage("API device approved response \(changeResponse)")
        } catch {
            FileLog.shared.addMessage("Failed to approve device \(error.localizedDescription)")
            completion?((error as NSError).isConnectivityError ? .failure(APIError.NO_CONNECTION) : .failure(error))
        }
    }

    override func apiTokenAcquisitionFailed() {
        FileLog.shared.addMessage("[DeviceApproveTask] Token acquisition failed")
        completion?(.failure(APIError.UNKNOWN))
    }
}
