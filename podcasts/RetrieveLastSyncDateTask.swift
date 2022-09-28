import Foundation
import SwiftProtobuf

class RetrieveLastSyncDateTask: ApiBaseTask {
    var completion: ((String?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "user/last_sync_at"

        do {
            let lastSyncRequest = Api_EmptyRequest()
            let data = try lastSyncRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let lasySyncAt = try Api_UserLastSyncAtResponse(serializedData: responseData).lastSyncAt

                completion?(lasySyncAt)
            } catch {
                print("Decoding last sync at failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            print("retrieve last sync at failed \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
