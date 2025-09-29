import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrievePlaylistsTask: ApiBaseTask {
    var completion: (([(EpisodeFilter, [Episode])]?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/playlist/list"

        do {
            var playlistRequest = Api_UserPlaylistListRequest()
            playlistRequest.m = ServerConstants.Values.apiScope
            let data = try playlistRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let serverPlaylists = try Api_UserPlaylistListResponse(serializedData: responseData).playlists
                if serverPlaylists.count == 0 {
                    completion?(nil)

                    return
                }

                let result = serverPlaylists.map { serverPlaylist in
                    let episodes = serverPlaylist.episodes.map {
                        Episode($0)
                    }
                    let orderedEpisodes = episodes.sorted { serverPlaylist.episodeOrder.firstIndex(of: $0.uuid) ?? 0 < serverPlaylist.episodeOrder.firstIndex(of: $1.uuid) ?? 0 }
                    return (convertFromProto(serverPlaylist), orderedEpisodes)
                }

                completion?(result)
            } catch {
                FileLog.shared.addMessage("Decoding playlists failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            FileLog.shared.addMessage("retrieve playlists failed \(error.localizedDescription)")
            completion?(nil)
        }
    }

    private func convertFromProto(_ protoFilter: Api_PlaylistSyncResponse) -> EpisodeFilter {
        let converted = EpisodeFilter()
        converted.customIcon = protoFilter.iconID.value
        converted.filterAllPodcasts = protoFilter.allPodcasts.value
        converted.filterAudioVideoType = protoFilter.audioVideo.value
        converted.filterDownloaded = protoFilter.downloaded.value
        converted.filterNotDownloaded = protoFilter.notDownloaded.value
        converted.filterFinished = protoFilter.finished.value
        converted.filterPartiallyPlayed = protoFilter.partiallyPlayed.value
        converted.filterStarred = protoFilter.starred.value
        converted.filterUnplayed = protoFilter.unplayed.value
        converted.filterHours = protoFilter.filterHours.value
        converted.playlistName = protoFilter.title
        converted.sortType = protoFilter.sortType.value
        converted.uuid = protoFilter.uuid
        converted.podcastUuids = protoFilter.podcastUuids
        converted.wasDeleted = protoFilter.isDeleted.value
        converted.sortPosition = protoFilter.sortPosition.value
        converted.manual = protoFilter.manual.value
        return converted
    }
}
