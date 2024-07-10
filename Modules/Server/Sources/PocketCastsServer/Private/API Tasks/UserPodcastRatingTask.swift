import Foundation
import PocketCastsUtils
import SwiftProtobuf

public struct UserPodcastRating: Codable {
    public let podcastRating: UInt32
    public let podcastUuid: String
    public let modifiedAt: Date?
}

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
