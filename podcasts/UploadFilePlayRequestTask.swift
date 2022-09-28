import DataModel
import Foundation
import SwiftProtobuf
import Utils

class UploadFilePlayRequestTask: ApiBaseTask {
    var completion: ((URL?) -> Void)?
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "files/play/" + episode.uuid
        do {
            let (response, httpStatus) = getToServer(url: url, token: token)

            guard let responseData = response, httpStatus?.statusCode == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("Upload file play request failed \(httpStatus?.statusCode ?? -1)")
                completion?(nil)
                return
            }

            do {
                let playResponse = try Files_FilePlayResponse(serializedData: responseData)
                FileLog.shared.addMessage("Upload play  response \(playResponse)")
                completion?(URL(string: playResponse.url))
            } catch {
                FileLog.shared.addMessage("Upload request response failed")
            }
        }
    }
}
