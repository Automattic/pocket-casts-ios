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
                FileLog.shared.addMessage("Failed to get rating for podcast \(uuid) because response is empty")
                completion?(false)
                return
            }

            if httpStatus == ServerConstants.HttpConstants.ok {
                FileLog.shared.addMessage("Add rating success for podcast \(uuid)")
            } else {
                FileLog.shared.addMessage("Failed to get rating for podcast \(uuid), http status \(httpStatus)")
            }
            completion?(httpStatus == ServerConstants.HttpConstants.ok)
        } catch {
            FileLog.shared.addMessage("Failed to serialize Api_PodcastRatingAddRequest \(error.localizedDescription) for podcast \(uuid)")
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
            var request = Api_PodcastRatingShowRequest()
            request.podcastUuid = uuid

            let data = try request.serializedData()

            let (response, httpStatus) = postToServer(url: urlString, token: token, data: data)

            guard let responseData = response, httpStatus == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("Failed to get rating for podcast \(uuid), http status \(httpStatus)")
                completion?(false, nil)
                return
            }

            do {
                let result = try Api_PodcastRating(serializedData: responseData)
                let userRating = UserPodcastRating(podcastRating: result.podcastRating,
                                                   podcastUuid: result.podcastUuid,
                                                   modifiedAt: result.modifiedAt.date)
                completion?(true, userRating)

                FileLog.shared.addMessage("Get rating success for podcast \(uuid)")
            } catch {
                FileLog.shared.addMessage("Failed to serialize Api_PodcastRating \(error.localizedDescription) for podcast \(uuid)")
                completion?(false, nil)
            }
        } catch {
            FileLog.shared.addMessage("Failed to serialize Api_PodcastRatingShowRequest \(error.localizedDescription) for podcast \(uuid)")
            completion?(false, nil)
        }
    }
}

public struct UserPodcastRating: Codable {
    public let podcastRating: UInt32
    public let podcastUuid: String
    public let modifiedAt: Date
}
