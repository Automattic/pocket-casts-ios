import Foundation
import PocketCastsUtils
import SwiftProtobuf

class RetrieveEpisodesTask: ApiBaseTask {
    var completion: (([EpisodeSyncInfo]?) -> Void)?

    private var podcastUuid: String

    private lazy var addPodcastGroup: DispatchGroup = {
        let dispatchGroup = DispatchGroup()

        return dispatchGroup
    }()

    private var convertedEpisodes = [EpisodeSyncInfo]()

    init(podcastUuid: String) {
        self.podcastUuid = podcastUuid

        super.init()
    }

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/podcast/episodes"

        do {
            var episodesRequest = Api_UuidRequest()
            episodesRequest.m = ServerConstants.Values.apiScope
            episodesRequest.uuid = podcastUuid
            let data = try episodesRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let syncEpisodes = try Api_SyncEpisodesResponse(serializedData: responseData).episodes

                for syncEpisode in syncEpisodes {
                    let convertedEpisode = convertFromProto(syncEpisode)
                    convertedEpisodes.append(convertedEpisode)
                }

                completion?(convertedEpisodes)
            } catch {
                FileLog.shared.addMessage("Decoding episodes failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            FileLog.shared.addMessage("retrieve episodes failed \(error.localizedDescription)")
            completion?(nil)
        }
    }

    private func convertFromProto(_ protoEpisode: Api_EpisodeSyncResponse) -> EpisodeSyncInfo {
        var episode = EpisodeSyncInfo()
        episode.uuid = protoEpisode.uuid
        episode.duration = Int(protoEpisode.duration)
        episode.isArchived = protoEpisode.isDeleted
        episode.playedUpTo = Int(protoEpisode.playedUpTo)
        episode.playingStatus = Int(protoEpisode.playingStatus)
        episode.starred = protoEpisode.starred
        episode.deselectedChapters = protoEpisode.deselectedChapters

        return episode
    }
}
