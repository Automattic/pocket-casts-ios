import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrievePlaylistsTask: ApiBaseTask {
    var completion: (([EpisodeFilter]?) -> Void)?

    private var playlists = [EpisodeFilter]()

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

                var addedEpisodes: [Episode] = []
                for serverPlaylist in serverPlaylists {
                    let convertedPlaylist = convertFromProto(serverPlaylist)

                    // Add missing episodes
                    let serverSet = Set(serverPlaylist.episodeOrder)
                    let matchedEpisodes = DataManager.sharedManager.playlistEpisodes(for: convertedPlaylist).map { $0.uuid }
                    let missingEpisodes = serverSet.subtracting(matchedEpisodes)

                    let episodes: [Episode] = missingEpisodes.compactMap { episode in
                        let playlistEpisode = serverPlaylist.episodes.first(where: { $0.episode == episode })

                        guard let playlistEpisode else { return nil }
                        return Episode(playlistEpisode)
                    }
                    addedEpisodes = episodes
                    DataManager.sharedManager.add(episodes: addedEpisodes, to: convertedPlaylist)
                    DataManager.sharedManager.save(playlist: convertedPlaylist)

                    playlists.append(convertedPlaylist)
                }


                completion?(playlists)
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
