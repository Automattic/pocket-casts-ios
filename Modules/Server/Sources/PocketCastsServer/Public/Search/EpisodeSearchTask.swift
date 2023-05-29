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

        let json: [String: Any] = ["term": term]

        let jsonData = try JSONSerialization.data(withJSONObject: json)

        request.httpBody = jsonData

        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let envelope = try decoder.decode(EpisodeSearchEnvelope.self, from: data)
        return envelope.episodes
    }
}
