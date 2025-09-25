import Foundation

struct PredictiveSearchEnvelope: Decodable {
    public let results: [PredictiveSearchResult]
}

public struct PredictivePodcastSearchResult: Codable, Hashable {
    let uuid: String
    let title: String
    let author: String
}

public struct PredictiveSearchResult: Codable, Hashable {
    public let type: String
    public let value: String?
    public let podcast: PredictivePodcastSearchResult?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        switch type {
            case "term":
                self.value = try container.decode(String.self, forKey: .value)
                self.podcast = nil
            case "podcast":
                self.value = nil
                self.podcast = try container.decode(PredictivePodcastSearchResult.self, forKey: .value)
            default:
                self.value = try container.decode(String.self, forKey: .value)
                self.podcast = nil
        }
    }
}

public class PredictiveSearchTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(term: String) async throws -> [PredictiveSearchResult] {
        let searchURL = URL(string: "\(ServerConstants.Urls.cache())/autocomplete/search?term=\(term)")!
        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"

        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let envelope = try decoder.decode(PredictiveSearchEnvelope.self, from: data)
        return envelope.results
    }
}
