import Foundation
import PocketCastsDataModel

public struct PodcastRating: Codable {
    public let total: Int
    public let average: Double
}

public struct UserPodcastRating: Codable {
    public let podcastRating: Int
    public let podcastUuid: String
    public let modifiedAt: Date?
}

public struct PodcastRatingTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Retrieves the star rating and total for a single podcast
    public func retrieve(for podcastUuid: String) async throws -> PodcastRating? {
        let urlString = "\(ServerConstants.Urls.cache())podcast/rating/\(podcastUuid)"
        let task = JSONDecodableURLTask<PodcastRating>(session: session)

        return try await task.get(urlString: urlString)
    }
    
    public func addRating(uuid: String, rating: Double) async throws -> UserPodcastRating {
        let urlString = "\(ServerConstants.Urls.cache())user/podcast_rating/add"
        let json: [String: Any] = ["podcastRating": rating,
                                   "podcastUuid": uuid]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let task = JSONDecodableURLTask<UserPodcastRating>(session: session, decoder: decoder)
        return try await task.post(urlString: urlString, body: json)
    }

    public func getRatingsList() async throws -> [UserPodcastRating] {
        let urlString = "\(ServerConstants.Urls.cache())user/podcast_rating/list"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let task = JSONDecodableURLTask<[UserPodcastRating]>(session: session, decoder: decoder)
        return try await task.get(urlString: urlString)
    }
}
