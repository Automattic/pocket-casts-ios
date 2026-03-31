import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class StarredSyncTask: ApiBaseTask {
    private let episode: Episode

    init(episode: Episode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "sync/update_episode_star"
        do {
            var updateRequest = Api_UpdateEpisodeStarRequest()
            updateRequest.uuid = episode.uuid
            updateRequest.podcast = episode.podcastUuid
            updateRequest.star = episode.keepEpisode

            let data = try updateRequest.serializedData()
            let (_, httpStatus) = postToServer(url: url, token: token, data: data)

            if httpStatus == ServerConstants.HttpConstants.ok {
                DataManager.sharedManager.clearKeepEpisodeModified(episode: episode)
            } else {
                FileLog.shared.addMessage("Save star failed \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("StarredSyncTask: Protobuf Encoding failed \(error.localizedDescription)")
        }
    }
}
