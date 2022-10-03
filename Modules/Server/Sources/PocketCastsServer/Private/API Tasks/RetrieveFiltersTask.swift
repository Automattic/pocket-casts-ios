import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveFiltersTask: ApiBaseTask {
    var completion: (([EpisodeFilter]?) -> Void)?

    private var filters = [EpisodeFilter]()

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/playlist/list"

        do {
            var filterRequest = Api_UserPlaylistListRequest()
            filterRequest.m = ServerConstants.Values.apiScope
            let data = try filterRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let serverFilters = try Api_UserPlaylistListResponse(serializedData: responseData).playlists
                if serverFilters.count == 0 {
                    completion?(nil)

                    return
                }

                for serverFilter in serverFilters {
                    if serverFilter.manual.value { continue } // we don't care about manual playlists

                    let convertedFilter = convertFromProto(serverFilter)
                    filters.append(convertedFilter)
                }

                completion?(filters)
            } catch {
                FileLog.shared.addMessage("Decoding filters failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            FileLog.shared.addMessage("retrieve filters failed \(error.localizedDescription)")
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

        return converted
    }
}
