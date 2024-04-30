import Foundation

/// Request information about an episode using the show notes endpoint
public actor ShowInfoDataRetriever {
    private var dataRequestMap: [String: Task<Data, Error>] = [:]

    private let cache: URLCache

    public init() {
        cache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "show_notes")
    }

    public func loadEpisodeData(
        for podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        if let data = try? await loadShowInfoData(for: podcastUuid) {
            if let showInfo = try? (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])?["podcast"] as? [String: Any],
               let episodes = showInfo["episodes"] as? [Any] {
                // Return the JSON string for the requested episode
                if let episode = episodes.first(where: { (($0 as? [String: Any])?["uuid"] as? String) == episodeUuid }),
                   let jsonData = try? JSONSerialization.data(withJSONObject: episode),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    return jsonString
                }
            }
        }

        return nil
    }

    public func loadShowInfoData(
        for podcastUuid: String
    ) async throws -> Data {
        if let task = dataRequestMap[podcastUuid] {
            return try await task.value
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        var request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if let cachedResponse = cache.cachedResponse(for: request) {
            if let etag = cachedResponse.response.etag {
                request.setValue(etag, forHTTPHeaderField: ServerConstants.HttpHeaders.ifNoneMatch)
            }

            if let lastModified = cachedResponse.response.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: ServerConstants.HttpHeaders.ifModifiedSince)
            }
        }

        let task = Task<Data, Error> {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if response.extractStatusCode() == 200 {
                    let responseToCache = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(responseToCache, for: request)
                } else if let data = cache.cachedResponse(for: request)?.data {
                    dataRequestMap[podcastUuid] = nil
                    return data
                }

                dataRequestMap[podcastUuid] = nil
                return data
            } catch {
                dataRequestMap[podcastUuid] = nil
                throw error
            }
        }
        dataRequestMap[podcastUuid] = task

        return try await task.value
    }
}
