import Foundation
import PocketCastsServer

struct EpisodeSearchEnvelope: Decodable {
    let episodes: [EpisodeSearchResult]
}

struct EpisodeSearchResult: Decodable {
    let uuid: String
    let title: String
    let publishedDate: Date
    let duration: Double?
    let podcastUuid: String
    let podcastTitle: String
}

class EpisodeSearchTask {
    var session = URLSession.shared

    func search(term: String) async throws -> [EpisodeSearchResult] {
        let searchURL = URL(string: "https://podcast-api.pocketcasts.net/episode/search")!
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"

        let json: [String: Any] = ["term": term.replacingOccurrences(of: " ", with: "+")]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

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
