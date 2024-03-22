import Foundation

/// Request information about an episode using the show notes endpoint
public actor ShowInfoDataRetriever {
    private let showNotesUrlCache: URLCache

    private var dataRequestMap: [String: Task<Data, Error>] = [:]

    public init() {
        showNotesUrlCache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "show_notes")
    }

    public func loadShowInfoData(
        for podcastUuid: String
    ) async throws -> Data {
        if let task = dataRequestMap[podcastUuid] {
            return try await task.value
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if let cachedResponse = showNotesUrlCache.cachedResponse(for: request) {
            return cachedResponse.data
        }

        let task = Task<Data, Error> {
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseToCache = CachedURLResponse(response: response, data: data)
            showNotesUrlCache.storeCachedResponse(responseToCache, for: request)
            dataRequestMap[podcastUuid] = nil
            return data
        }

        dataRequestMap[podcastUuid] = task

        return try await task.value
    }
}
