import Foundation
import SwiftProtobuf

class RetrievePodcastsTask: ApiBaseTask {
    var completion: (([PodcastSyncInfo]?) -> Void)?

    private var podcasts = [PodcastSyncInfo]()

    override func apiTokenAcquired(token: String) {
        let url = Server.Urls.api + "user/podcast/list"

        do {
            var podcastRequest = Api_UserPodcastListRequest()
            podcastRequest.m = Constants.Values.apiScope
            let data = try podcastRequest.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == Server.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                let serverPodcasts = try Api_UserPodcastListResponse(serializedData: responseData).podcasts
                if serverPodcasts.count == 0 {
                    completion?(nil)

                    return
                }

                for serverPodcast in serverPodcasts {
                    let convertedPodcast = convertFromProto(serverPodcast)
                    podcasts.append(convertedPodcast)
                }

                completion?(podcasts)
            } catch {
                print("Decoding podcasts failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            print("retrieve podcasts failed \(error.localizedDescription)")
            completion?(nil)
        }
    }

    private func convertFromProto(_ protoPodcast: Api_UserPodcastResponse) -> PodcastSyncInfo {
        var podcast = PodcastSyncInfo()
        podcast.uuid = protoPodcast.uuid
        podcast.autoStartFrom = Int(protoPodcast.autoStartFrom)
        podcast.autoSkipLast = Int(protoPodcast.autoSkipLast)

        return podcast
    }
}
