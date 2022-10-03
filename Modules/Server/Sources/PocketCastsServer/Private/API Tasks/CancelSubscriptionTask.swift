import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class CancelSubscriptionTask: ApiBaseTask {
    private let bundleUuid: String

    var completion: ((Bool) -> Void)?

    init(bundleUuid: String) {
        self.bundleUuid = bundleUuid

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "subscription/cancel/web"
        do {
            var cancelRequest = Api_CancelUserSubscriptionRequest()
            cancelRequest.bundleUuid = bundleUuid
            let data = try cancelRequest.serializedData()

            let (_, httpStatus) = postToServer(url: url, token: token, data: data)

            completion?(httpStatus == ServerConstants.HttpConstants.ok)
        } catch {
            FileLog.shared.addMessage("CancelSubscriptionTask: Protobuf Encoding failed \(error.localizedDescription)")
            completion?(false)
        }
    }
}
