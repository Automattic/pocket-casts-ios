import Foundation

/// Request information about an episode using the show notes endpoint
public actor PodcastIndexChapterDataRetriever {
    private let podcastIndexChaptersCache: URLCache

    private var dataRequestMap: [String: Task<Data, Error>] = [:]

    public init() {
        podcastIndexChaptersCache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "show_notes")
    }

    public func loadChapters(_ urlString: String) async throws -> Data {
        if let task = dataRequestMap[urlString] {
            return try await task.value
        }

        guard let url = URL(string: urlString) else {
            throw Errors.malformedURL
        }

        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if let cachedResponse = podcastIndexChaptersCache.cachedResponse(for: request) {
            return cachedResponse.data
        }

        let task = Task<Data, Error> {
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseToCache = CachedURLResponse(response: response, data: data)
            podcastIndexChaptersCache.storeCachedResponse(responseToCache, for: request)
            dataRequestMap[urlString] = nil
            return data
        }

        dataRequestMap[urlString] = task

        return try await task.value
    }

    enum Errors: Error {
        case malformedURL
    }
}
