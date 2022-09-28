import DataModel
import Foundation
import SwiftProtobuf
import Utils

class ChangeEmailTask: ApiBaseTask {
    var completion: ((Bool) -> Void)?

    private var newEmail: String
    private var password: String

    init(newEmail: String, password: String) {
        self.newEmail = newEmail
        self.password = password
        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "user/change_email"

        do {
            var changeRequest = Api_UserChangeEmailRequest()
            changeRequest.email = newEmail
            changeRequest.password = password
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
                FileLog.shared.addMessage("API change email response \(result)")
            } catch {
                FileLog.shared.addMessage("Failed to change email \(error.localizedDescription)")
                completion?(false)
            }
        } catch {
            FileLog.shared.addMessage("Failed to change email")
            completion?(false)
        }
    }
}
