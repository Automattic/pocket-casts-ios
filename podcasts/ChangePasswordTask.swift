import DataModel
import Foundation
import SwiftProtobuf
import Utils

class ChangePasswordTask: ApiBaseTask {
    var completion: ((Bool) -> Void)?

    private var oldPassword: String
    private var newPassword: String

    init(currentPassword: String, newPassword: String) {
        self.newPassword = newPassword
        oldPassword = currentPassword
        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "user/change_password"

        do {
            var changeRequest = Api_UserChangePasswordRequest()
            changeRequest.oldPassword = oldPassword
            changeRequest.newPassword = newPassword
            changeRequest.scope = Constants.Values.apiScope

            let data = try changeRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                completion?(false)

                return
            }

            do {
                let result = try Api_UserChangeResponse(serializedData: responseData)
                completion?(result.success.value)
                FileLog.shared.addMessage("API change password response \(result)")
            } catch {
                FileLog.shared.addMessage("Failed to change password \(error.localizedDescription)")
                completion?(false)
            }
        } catch {
            FileLog.shared.addMessage("Failed to change password")
            completion?(false)
        }
    }
}
