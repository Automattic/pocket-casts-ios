import Foundation

public struct EpisodeSearchResult: Codable, Hashable {
    public let uuid: String
    public let title: String
    public let publishedDate: Date
    public let duration: Double?
    public let podcastUuid: String
    public let podcastTitle: String
    public let state: State?

    public init(uuid: String, title: String, publishedDate: Date, state: State? = nil, duration: Double? = nil, podcastUuid: String, podcastTitle: String) {
        self.uuid = uuid
        self.title = title
        self.publishedDate = publishedDate
        self.state = state
        self.duration = duration
        self.podcastUuid = podcastUuid
        self.podcastTitle = podcastTitle
    }

    public enum State: Codable {
        case normal
        case archived
        case unavailable

        public var isNormal: Bool {
            switch self {
            case .normal:
                true
            default:
                false
            }
        }
    }
}
