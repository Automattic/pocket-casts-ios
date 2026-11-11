import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class PositionSyncTask: ApiBaseTask, @unchecked Sendable {
    private let upTo: TimeInterval
    private let duration: TimeInterval
    private let episode: Episode

    init(upTo: TimeInterval, duration: TimeInterval, episode: Episode, urlConnection: URLConnection = URLConnection(handler: URLSession.shared)) {
        self.upTo = upTo
        self.duration = duration
        self.episode = episode

        super.init(urlConnection: urlConnection)
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "sync/update_episode"
        do {
            var updateRequest = Api_UpdateEpisodeRequest()
            updateRequest.uuid = episode.uuid
            updateRequest.podcast = episode.podcastUuid
            let position = Int32(exactly: upTo.rounded(.towardZero))
            if let position {
                updateRequest.position = Google_Protobuf_Int32Value(position)
            }
            updateRequest.status = episode.playingStatus
            updateRequest.duration = Int32(exactly: duration.rounded(.towardZero)) ?? 0

            let data = try updateRequest.serializedData()
            let (_, httpStatus) = postToServer(url: url, token: token, data: data)

            if httpStatus == ServerConstants.HttpConstants.ok {
                FileLog.shared.addMessage("Sent position \(position.map(String.init) ?? "none") status \(episode.playingStatus) for episode \(episode.displayableTitle()) to server")
            } else {
                FileLog.shared.addMessage("Save position failed \(httpStatus)")
            }
        } catch {
            FileLog.shared.addMessage("PositionSyncTask: Protobuf Encoding failed \(error.localizedDescription)")
        }
    }
}
