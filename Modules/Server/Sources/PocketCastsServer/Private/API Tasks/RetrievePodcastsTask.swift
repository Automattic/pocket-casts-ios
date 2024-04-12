import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrievePodcastsTask: ApiBaseTask {
    var completion: (([PodcastSyncInfo]?, [FolderSyncInfo]?, Bool) -> Void)?

    override func apiTokenAcquired(token: String) {
        // this endpoint now returns folders and podcasts
        let url = ServerConstants.Urls.api() + "user/podcast/list"

        do {
            var podcastRequest = Api_UserPodcastListRequest()
            podcastRequest.m = ServerConstants.Values.apiScope
            let data = try podcastRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(nil, nil, false)

                return
            }

            do {
                let response = try Api_UserPodcastListResponse(serializedData: responseData)

                var podcasts = [PodcastSyncInfo]()
                for serverPodcast in response.podcasts {
                    let convertedPodcast = convertPodcastFromProto(serverPodcast)
                    podcasts.append(convertedPodcast)
                }

                var folders = [FolderSyncInfo]()
                for serverFolder in response.folders {
                    let convertedFolder = convertFolderFromProto(serverFolder)
                    folders.append(convertedFolder)
                }

                completion?(podcasts, folders, true)
            } catch {
                FileLog.shared.addMessage("Decoding podcast list failed \(error.localizedDescription)")
                completion?(nil, nil, false)
            }
        } catch {
            FileLog.shared.addMessage("retrieve podcast list failed \(error.localizedDescription)")
            completion?(nil, nil, false)
        }
    }

    private func convertPodcastFromProto(_ protoPodcast: Api_UserPodcastResponse) -> PodcastSyncInfo {
        var podcast = PodcastSyncInfo()
        podcast.uuid = protoPodcast.uuid
        podcast.autoStartFrom = Int(protoPodcast.autoStartFrom)
        podcast.autoSkipLast = Int(protoPodcast.autoSkipLast)
        podcast.folderUuid = (protoPodcast.hasFolderUuid && protoPodcast.folderUuid.value != DataConstants.homeGridFolderUuid) ? protoPodcast.folderUuid.value : nil
        podcast.sortPosition = protoPodcast.hasSortPosition ? protoPodcast.sortPosition.value : nil
        podcast.dateAdded = protoPodcast.hasDateAdded ? protoPodcast.dateAdded.date : nil
        var settings = PodcastSettings.defaults
        settings.processSettings(protoPodcast.settings)
        podcast.settings = settings

        return podcast
    }

    private func convertFolderFromProto(_ protoFolder: Api_PodcastFolder) -> FolderSyncInfo {
        let convertedSortType = Int32(ServerConverter.convertToClientSortType(serverType: protoFolder.podcastsSortType))

        return FolderSyncInfo(uuid: protoFolder.folderUuid, name: protoFolder.name, color: protoFolder.color, sortOrder: protoFolder.sortPosition, sortType: convertedSortType, addedDate: protoFolder.dateAdded.date)
    }
}
