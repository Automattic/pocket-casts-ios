import Foundation

struct EpisodeSearchEnvelope: Decodable {
    public let episodes: [EpisodeSearchResult]
}

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

public class EpisodeSearchTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(term: String) async throws -> [EpisodeSearchResult] {
        let searchURL = URL(string: "\(ServerConstants.Urls.cache())episode/search")!
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        request.addLocalizationHeaders()

        let json: [String: Any] = ["term": term]

        let jsonData = try JSONSerialization.data(withJSONObject: json)

        request.httpBody = jsonData

        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let envelope = try decoder.decode(EpisodeSearchEnvelope.self, from: data)
        return envelope.episodes
    }
}
