import Foundation

struct PredictiveSearchEnvelope: Decodable {
    public let results: [PredictiveSearchResult]
}

public struct PredictivePodcastSearchResult: Codable, Hashable {
    let uuid: String
    let title: String
    let author: String
}

public enum PredictiveSearchResultType: Hashable {
    case unknown(String)
    case term(String)
    case podcast(PredictivePodcastSearchResult)
}

public struct PredictiveSearchResult: Decodable, Hashable {
    public let type: PredictiveSearchResultType

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
            case "term":
                let value = try container.decode(String.self, forKey: .value)
                self.type = .term(value)
            case "podcast":
                let podcast = try container.decode(PredictivePodcastSearchResult.self, forKey: .value)
                self.type = .podcast(podcast)
            default:
                let value = try container.decode(String.self, forKey: .value)
                self.type = .unknown(value)
        }
    }
}

public class PredictiveSearchTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(term: String) async throws -> [PredictiveSearchResult] {
        var components = URLComponents(string: ServerConstants.Urls.search + "autocomplete/search")
        components?.queryItems = [URLQueryItem(name: "q", value: term)]
        guard let searchURL = components?.url else {
            throw URL.URLCreationError.invalidURLString
        }
        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"
        request.addLocalizationHeaders()

        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let envelope = try decoder.decode(PredictiveSearchEnvelope.self, from: data)
        return envelope.results
    }
}
