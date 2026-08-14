import Foundation

public struct EpisodeSearchResult: Codable, Hashable {
    public let uuid: String
    public let title: String
    public let publishedDate: Date
    public let duration: Double?
    public let podcastUuid: String
    public let podcastTitle: String
    public let state: State?
    public let hasVideo: Bool
    public let videoURL: URL?

    enum CodingKeys: String, CodingKey {
        case uuid, title, publishedDate, duration, podcastUuid, podcastTitle, state, hasVideo, videoURL
    }

    public init(uuid: String, title: String, publishedDate: Date, state: State? = nil, duration: Double? = nil, podcastUuid: String, podcastTitle: String, hasVideo: Bool = false, videoURL: URL? = nil) {
        self.uuid = uuid
        self.title = title
        self.publishedDate = publishedDate
        self.state = state
        self.duration = duration
        self.podcastUuid = podcastUuid
        self.podcastTitle = podcastTitle
        self.hasVideo = hasVideo
        self.videoURL = videoURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
        self.title = try container.decode(String.self, forKey: .title)
        self.publishedDate = try container.decode(Date.self, forKey: .publishedDate)
        self.duration = try? container.decodeIfPresent(Double.self, forKey: .duration)
        self.podcastUuid = try container.decode(String.self, forKey: .podcastUuid)
        self.podcastTitle = try container.decode(String.self, forKey: .podcastTitle)
        self.state = try? container.decodeIfPresent(State.self, forKey: .state)
        self.hasVideo = (try? container.decodeIfPresent(Bool.self, forKey: .hasVideo)) ?? false
        self.videoURL = try? container.decodeIfPresent(URL.self, forKey: .videoURL)
    }

    public init?(from combinedResult: CombinedSearchResult) {
        guard combinedResult.type == "episode" else {
            return nil
        }
        self.uuid = combinedResult.uuid
        self.title = combinedResult.title
        self.publishedDate = combinedResult.publishedDate ?? Date()
        self.state = .normal
        self.duration = combinedResult.duration
        self.podcastUuid = combinedResult.podcastUuid ?? ""
        self.podcastTitle = combinedResult.podcastTitle ?? ""
        self.hasVideo = combinedResult.hasVideo ?? false
        self.videoURL = combinedResult.videoUrl.flatMap { URL(string: $0) }
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
