import Foundation
import PocketCastsDataModel
import PocketCastsUtils
import SwiftProtobuf

class RetrieveRatingsTask: ApiBaseTask, @unchecked Sendable {
    var completion: (([UserPodcastRating]?) -> Void)?

    var success: Bool = false

    private var convertedRatings = [UserPodcastRating]()

    private lazy var addRatingGroup: DispatchGroup = {
        let dispatchGroup = DispatchGroup()

        return dispatchGroup
    }()

    override func apiTokenAcquired(token: String) {
        let url = ServerConstants.Urls.api() + "user/podcast_rating/list"

        do {
            let (response, httpStatus) = getToServer(url: url, token: token)

            guard let responseData = response, httpStatus?.statusCode == ServerConstants.HttpConstants.ok else {
                completion?(nil)
                return
            }

            let serverRatings = try Api_PodcastRatingsResponse(serializedBytes: responseData).podcastRatings
            if serverRatings.count == 0 {
                success = true
                completion?(convertedRatings)

                return
            }

            convertedRatings = serverRatings.map { rating in
                UserPodcastRating(podcastRating: rating.podcastRating, podcastUuid: rating.podcastUuid, modifiedAt: rating.modifiedAt.date)
            }

            DataManager.sharedManager.ratings.ratings = convertedRatings

            success = true

            completion?(convertedRatings)
        } catch {
            FileLog.shared.addMessage("Decoding ratings failed \(error.localizedDescription)")
            completion?(nil)
        }
    }
}
