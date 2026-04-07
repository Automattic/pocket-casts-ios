import Foundation

public struct UserPodcastRating: Codable {
    public let podcastRating: UInt32
    public let podcastUuid: String
    public let modifiedAt: Date

    public init(podcastRating: UInt32, podcastUuid: String, modifiedAt: Date) {
        self.podcastRating = podcastRating
        self.podcastUuid = podcastUuid
        self.modifiedAt = modifiedAt
    }
}
