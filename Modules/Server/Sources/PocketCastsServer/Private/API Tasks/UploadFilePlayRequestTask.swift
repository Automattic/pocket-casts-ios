import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class UploadFilePlayRequestTask: ApiBaseTask {
    var completion: ((URL?) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files/play/" + episode.uuid
        do {
            let (response, httpStatus) = getToServer(url: url, token: token)

            guard let responseData = response else {
                FileLog.shared.addMessage("Upload file play request missing response data \(httpStatus?.statusCode ?? -1)")
                completion?(nil)
                return
            }

            do {
                let playResponse = try Files_FilePlayResponse(serializedData: responseData)
                guard httpStatus?.statusCode == ServerConstants.HttpConstants.ok else {
                    FileLog.shared.addMessage("Upload file play request failed \(httpStatus?.statusCode ?? -1) with message: \(playResponse.textFormatString())")
                    completion?(nil)
                    return
                }
                FileLog.shared.addMessage("Upload play response successful)")
                completion?(URL(string: playResponse.url))
            } catch {
                FileLog.shared.addMessage("Upload Play request response failed \(error.localizedDescription)")
                completion?(nil)
            }
        }
    }
}
