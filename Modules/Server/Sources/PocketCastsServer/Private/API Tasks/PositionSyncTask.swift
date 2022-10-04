import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class PositionSyncTask: ApiBaseTask {
    private let upTo: TimeInterval
    private let duration: TimeInterval
    private let episode: Episode

    init(upTo: TimeInterval, duration: TimeInterval, episode: Episode) {
        self.upTo = upTo
        self.duration = duration
        self.episode = episode

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "sync/update_episode"
        do {
            var updateRequest = Api_UpdateEpisodeRequest()
            updateRequest.uuid = episode.uuid
            updateRequest.podcast = episode.podcastUuid
            let upToAsInt = Int32(upTo)
            updateRequest.position = Google_Protobuf_Int32Value(upToAsInt)
            updateRequest.status = episode.playingStatus
            updateRequest.duration = Int32(duration)

            let data = try updateRequest.serializedData()
            let (_, httpStatus) = postToServer(url: url, token: token, data: data)

            if httpStatus == ServerConstants.HttpConstants.ok {
                FileLog.shared.addMessage("Sent position \(upToAsInt) status \(episode.playingStatus) for episode \(episode.displayableTitle()) to server")
            } else {
                FileLog.shared.addMessage("Save position failed \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("PositionSyncTask: Protobuf Encoding failed \(error.localizedDescription)")
        }
    }
}
