import DataModel
import Foundation
import SwiftProtobuf

class StarredSyncTask: ApiBaseTask {
    private let episode: Episode

    init(episode: Episode) {
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "sync/update_episode_star"
        do {
            var updateRequest = Api_UpdateEpisodeStarRequest()
            updateRequest.uuid = episode.uuid
            updateRequest.podcast = episode.podcastUuid
            updateRequest.star = episode.keepEpisode

            let data = try updateRequest.serializedData()
            let (_, httpStatus) = postToServer(url: url, token: token, data: data)

            if httpStatus == Server.HttpConstants.ok {
                DataManager.sharedManager.clearKeepEpisodeModified(episode: episode)
            } else {
                print("Save star failed \(httpStatus)")
            }
        } catch {
            print("Protobuf Encoding failed")
        }
    }
}
