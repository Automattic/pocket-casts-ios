import Foundation
import PocketCastsUtils
import SwiftProtobuf

class DeleteAccountTask: ApiBaseTask {
    var completion: ((Bool, String?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/delete_account"

        do {
            let request = Api_BasicRequest()
            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(false, nil)

                return
            }

            let changeResponse = try Api_UserChangeResponse(serializedData: responseData)
            let success = changeResponse.success.value
            let message = changeResponse.message

            completion?(success, message)
        } catch {
            FileLog.shared.addMessage("Delete account failed \(error.localizedDescription)")
            completion?(false, nil)
        }
    }
}
