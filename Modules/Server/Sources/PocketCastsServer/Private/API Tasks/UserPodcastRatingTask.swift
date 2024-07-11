import Foundation
import PocketCastsUtils
import SwiftProtobuf

class UserPodcastRatingAddTask: ApiBaseTask {
    var completion: ((Bool) -> Void)?

    private let uuid: String
    private let rating: UInt32

    init(uuid: String, rating: UInt32) {
        self.uuid = uuid
        self.rating = rating
    }

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())user/podcast_rating/add"

        do {
            var request = Api_PodcastRatingAddRequest()
            request.podcastRating = rating
            request.podcastUuid = uuid

            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: urlString, token: token, data: data)

            if response == nil {
                completion?(false)
                return
            }

            if httpStatus == ServerConstants.HttpConstants.ok {
                FileLog.shared.addMessage("Add rating success for podcast \(uuid)")
            } else {
                FileLog.shared.addMessage("Failed to add rating for podcast \(uuid)")
            }
            completion?(httpStatus == ServerConstants.HttpConstants.ok)
        } catch {
            FileLog.shared.addMessage("Failed to add rating \(error.localizedDescription) for podcast \(uuid)")
            completion?(false)
        }
    }
}

class UserPodcastRatingGetTask: ApiBaseTask {
    var completion: ((Bool, UserPodcastRating?) -> Void)?

    private let uuid: String

    init(uuid: String) {
        self.uuid = uuid
    }

    override func apiTokenAcquired(token: String) {
        let urlString = "\(ServerConstants.Urls.api())user/podcast_rating/show"

        do {
            var request = Api_PodcastRatingGetRequest()
            request.podcastUuid = uuid

            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: urlString, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                completion?(false, nil)
                return
            }

            do {
                let result = try Api_PodcastRatingResponse(serializedData: responseData)
                let userRating = UserPodcastRating(podcastRating: result.podcastRating.podcastRating,
                                                   podcastUuid: result.podcastRating.podcastUuid,
                                                   modifiedAt: result.podcastRating.modifiedAt.date)
                completion?(true, userRating)

                FileLog.shared.addMessage("Get rating success for podcast \(uuid)")
            } catch {
                FileLog.shared.addMessage("Failed to get rating \(error.localizedDescription) for podcast \(uuid)")
                completion?(false, nil)
            }
        } catch {
            FileLog.shared.addMessage("Failed to get rating \(error.localizedDescription) for podcast \(uuid)")
            completion?(false, nil)
        }
    }
}

public struct UserPodcastRating: Codable {
    public let podcastRating: UInt32
    public let podcastUuid: String
    public let modifiedAt: Date
}
