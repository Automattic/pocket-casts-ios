import Foundation
import PocketCastsServer
import PocketCastsUtils

public struct GeneratedMetadataEnvelope: Decodable {
    let summary: String
    let chapters: [GeneratedChapter]?
}

struct GeneratedChapter: Decodable {
    let title: String
    let timestamp: String
    let startTime: TimeInterval
}

/// Request information about an episode using the show notes endpoint
public actor GeneratedEpisodeMetadataRetriever {
    private let cache: URLCache

    private var dataRequestMap: [String: Task<GeneratedMetadataEnvelope, Error>] = [:]

    public init() {
        cache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "generated_episde_metadata")
    }

    private func buildGeneratedMetadataURL(podcastUuid: String, episodeUuid: String) -> String {
        return "\(ServerConstants.Urls.generatedTranscripts)\(podcastUuid)/\(episodeUuid)-meta.json"
    }

    public func loadMetadata(podcastUuid: String, episodeUuid: String) async throws -> GeneratedMetadataEnvelope {
        let urlString = buildGeneratedMetadataURL(podcastUuid: podcastUuid, episodeUuid: episodeUuid)

        if let task = dataRequestMap[urlString] {
            return try await task.value
        }

        guard let url = URL(string: urlString) else {
            throw Errors.malformedURL
        }

        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if let cachedResponse = cache.cachedResponse(for: request) {
            return try metadata(from: cachedResponse.data)
        }

        let task = Task<GeneratedMetadataEnvelope, Error> { [weak self] in
            guard let self else { throw TaskError.nilSelf }
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseToCache = CachedURLResponse(response: response, data: data)
            cache.storeCachedResponse(responseToCache, for: request)
            await setDataRequestMapToNil(for: urlString)

            return try await metadata(from: data)
        }

        dataRequestMap[urlString] = task

        return try await task.value
    }

    private func setDataRequestMapToNil(for urlString: String) {
        dataRequestMap[urlString] = nil
    }

    private func metadata(from data: Data) throws -> GeneratedMetadataEnvelope {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GeneratedMetadataEnvelope.self, from: data)
    }

    enum Errors: Error {
        case malformedURL
    }
}
