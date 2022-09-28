import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveFileUploadStatusTask: ApiBaseTask {
    private let episode: UserEpisode

    init(episode: UserEpisode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "files/upload/status/" + episode.uuid

        do {
            let (data, httpResponse) = getToServer(url: url, token: token, customHeaders: nil)

            if httpResponse?.statusCode == ServerConstants.HttpConstants.notModified {
                FileLog.shared.addMessage("RetrieveFileUploadStatusTask - not modified, no changes required")
                NotificationCenter.default.post(name: ServerNotifications.userEpisodesRefreshed, object: nil)
                return
            }

            guard let responseData = data, httpResponse?.statusCode == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("RetrieveFileUploadStatusTask  - server returned \(httpResponse?.statusCode ?? -1), upload marked as failed")

                DataManager.sharedManager.saveEpisode(uploadStatus: .uploadFailed, episode: episode)
                NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadStatusChanged, object: episode.uuid)
                return
            }

            do {
                let serverResponse = try Files_SuccessResponse(serializedData: responseData)
                FileLog.shared.addMessage("RetrieveFileUploadStatusTask  - server returned upload success =\(serverResponse.self)")
                if serverResponse.success {
                    DataManager.sharedManager.saveEpisode(uploadStatus: .uploaded, episode: episode)
                } else {
                    DataManager.sharedManager.saveEpisode(uploadStatus: .uploadFailed, episode: episode)
                }
                NotificationCenter.default.post(name: ServerNotifications.userEpisodeUploadStatusChanged, object: episode.uuid)
            } catch {
                FileLog.shared.addMessage("Decoding User episodes failed \(error.localizedDescription)")
            }
        }
    }
}
