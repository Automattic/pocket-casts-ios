import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf
import UIKit

class UploadImageDeleteTask: ApiBaseTask {
    var completion: ((Bool) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files/image/" + episode.uuid
        do {
            var deleteRequest = Files_FileDeleteRequest()
            deleteRequest.uuid = episode.uuid
            let data = try deleteRequest.serializedData()
            let (_, httpStatus) = deleteToServer(url: url, token: token, data: data)

            // if the delete request 404's, then it has already been deleted and this is also considered successful
            guard httpStatus == ServerConstants.HttpConstants.ok || httpStatus == ServerConstants.HttpConstants.notFound else {
                FileLog.shared.addMessage("Upload image file delete request failed \(httpStatus)")
                completion?(false)
                return
            }

            FileLog.shared.addMessage("Uploaded image file delete request successful")
            completion?(true)
        } catch {
            FileLog.shared.addMessage("FileDeleteRequest encoding failed \(error.localizedDescription)")
            completion?(false)
        }
    }
}
