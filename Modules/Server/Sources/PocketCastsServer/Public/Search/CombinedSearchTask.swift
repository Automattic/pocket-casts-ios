import Foundation

struct CombinedSearchEnvelope: Decodable {
    public let results: [CombinedSearchResult]
}

public enum CombinedSearchResultType: Hashable {
    case episode(EpisodeSearchResult)
    case podcast(PodcastFolderSearchResult)
}

public struct CombinedSearchResult: Decodable, Hashable {
    public let type: String
    public let uuid: String
    public let title: String
    public let publishedDate: Date?
    public let duration: Double?
    public let podcastUuid: String?
    public let podcastTitle: String?
    public let author: String?

    public var resolvedResultType: CombinedSearchResultType? {
        switch type {
            case "podcast":
                guard let podcast = PodcastFolderSearchResult(from: self) else {
                    return nil
                }
                return .podcast(podcast)
            case "episode":
            let episode = EpisodeSearchResult(uuid: self.uuid, title: self.title, publishedDate: self.publishedDate ?? Date.now, state: .normal, duration: duration, podcastUuid: self.podcastUuid ?? "", podcastTitle: self.podcastTitle ?? "")
                return .episode(episode)
            default:
                return nil
        }
    }
}

public class CombinedSearchTask {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(term: String) async throws -> [CombinedSearchResultType] {
        let components = URLComponents(string: ServerConstants.Urls.cache() + "search/combined")
        guard let searchURL = components?.url,
              let request = ServerHelper.createJsonRequest(url: searchURL, params: ["term": term], timeout: 10, cachePolicy: .reloadIgnoringCacheData)
        else {
            throw URL.URLCreationError.invalidURLString
        }

        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let envelope = try decoder.decode(CombinedSearchEnvelope.self, from: data)
        return envelope.results.compactMap { result in
            return result.resolvedResultType
        }
    }
}
