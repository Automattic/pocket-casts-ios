import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RecommendEpisodesTask: ApiBaseTask {
    var completion: ((Episode?) -> Void)?

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "discover/recommend_episodes"

        do {
            let request = Api_BasicRequest()
            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: url, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(nil)

                return
            }

            do {
                if let topEpisode = try Api_EpisodesResponse(serializedData: responseData).episodes.first {
                    let episode = Episode()
                    episode.uuid = topEpisode.uuid
                    episode.podcastUuid = topEpisode.podcastUuid
                    completion?(episode)
                } else {
                    completion?(nil)
                }
            } catch {
                FileLog.shared.addMessage("Decoding recommended episodes failed \(error.localizedDescription)")
                completion?(nil)
            }
        } catch {
            FileLog.shared.addMessage("Recommended episodes failed \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
