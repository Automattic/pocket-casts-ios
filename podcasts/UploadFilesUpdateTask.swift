import DataModel
import SwiftProtobuf
import UIKit
import Utils

class UploadFilesUpdateTask: ApiBaseTask {
    var completion: ((Int) -> Void)?

    private var episodes = [UserEpisode]()

    init(episodes: [UserEpisode]) {
        self.episodes = episodes

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "files"

        var updateRequest = Files_FileListUpdateRequest()

        for episode in episodes {
            var updateFile = Files_FileUpdate()
            updateFile.uuid = episode.uuid

            if episode.titleModified > 0 {
                updateFile.title = episode.title ?? "no name"
            }
            if episode.imageColorModified > 0 {
                updateFile.colour = Google_Protobuf_Int32Value(episode.imageColor)
            }
            if episode.playedUpToModified > 0, !episode.playedUpTo.isNaN, !episode.playedUpTo.isInfinite {
                updateFile.playedUpTo = Google_Protobuf_Int32Value(Int32(episode.playedUpTo))
            }
            if episode.playingStatusModified > 0 {
                updateFile.playingStatus = Google_Protobuf_Int32Value(episode.playingStatus)
            }
            if episode.durationModified > 0 {
                updateFile.duration = Google_Protobuf_Int64Value(Int64(episode.duration))
            }
            updateRequest.files.append(updateFile)
        }

        do {
            let data = try updateRequest.serializedData()
            let (_, httpStatus) = postToServer(url: url, token: token, data: data)

            guard httpStatus == Server.HttpConstants.ok else {
                FileLog.shared.addMessage("Upload file Update failed \(httpStatus)")
                completion?(httpStatus)
                return
            }
            print("Upload file update succeeded")
            episodes = episodes.map {
                $0.titleModified = 0
                $0.imageColorModified = 0
                $0.playingStatusModified = 0
                $0.playedUpToModified = 0
                $0.durationModified = 0
                return $0
            }

            DataManager.sharedManager.bulkSave(episodes: episodes)
            completion?(httpStatus)
            return
        } catch {
            print("Protobuf Encoding failed")
        }
    }
}
