import Foundation
import PocketCastsUtils

/// Request information about an episode using the show notes endpoint
public actor ShowInfoDataRetriever {
    private var dataRequestMap: [String: Task<Data, Error>] = [:]

    private let cache: URLCache

    public init() {
        cache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 100.megabytes, diskPath: "show_notes")
    }

    /// Try to load episode data from cache
    /// If it's not found, request it
    public func loadEpisodeDataFromCache(
        for podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        let request = URLRequest(url: url)

        if let cachedResponse = cache.cachedResponse(for: request),
            let metadata = extractMetadata(for: episodeUuid, from: cachedResponse.data) {
            FileLog.shared.addMessage("Show Info: returning cached data for episode \(episodeUuid)")
            return metadata
        }

        return try await loadEpisodeData(for: podcastUuid, episodeUuid: episodeUuid)
    }

    public func loadShowInfoData(
        for podcastUuid: String
    ) async throws -> Data {
        if let task = dataRequestMap[podcastUuid] {
            return try await task.value
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

        if let cachedResponse = cache.cachedResponse(for: URLRequest(url: url)) {
            if let etag = cachedResponse.response.etag {
                request.setValue(etag, forHTTPHeaderField: ServerConstants.HttpHeaders.ifNoneMatch)
            }

            if let lastModified = cachedResponse.response.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: ServerConstants.HttpHeaders.ifModifiedSince)
            }
        }

        FileLog.shared.addMessage("Show Info: requesting info for podcast \(podcastUuid)")

        let task = Task<Data, Error> { [weak self, request] in
            guard let self else { throw TaskError.nilSelf }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                if response.extractStatusCode() == 200 {
                    let responseToCache = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(responseToCache, for: request)
                    FileLog.shared.addMessage("Show Info: request succeeded for podcast \(podcastUuid).")
                } else if let data = cache.cachedResponse(for: request)?.data {
                    await setDataRequestMapToNil(for: podcastUuid)
                    FileLog.shared.addMessage("Show Info: request failed for podcast \(podcastUuid). Returning cached data")
                    return data
                }

                await setDataRequestMapToNil(for: podcastUuid)
                return data
            } catch {
                FileLog.shared.addMessage("Show Info: request failed for podcast \(podcastUuid): \(error.localizedDescription). Returning cached data")
                await setDataRequestMapToNil(for: podcastUuid)
                throw error
            }
        }
        dataRequestMap[podcastUuid] = task

        return try await task.value
    }

    private func setDataRequestMapToNil(for podcastUuid: String) {
        dataRequestMap[podcastUuid] = nil
    }

    private func loadEpisodeData(
        for podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        if let data = try? await loadShowInfoData(for: podcastUuid) {
            return extractMetadata(for: episodeUuid, from: data)
        }

        return nil
    }

    private func extractMetadata(for episodeUuid: String, from data: Data) -> String? {
        if let showInfo = try? (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])?["podcast"] as? [String: Any],
           let episodes = showInfo["episodes"] as? [Any] {
            // Return the JSON string for the requested episode
            if let episode = episodes.first(where: { (($0 as? [String: Any])?["uuid"] as? String) == episodeUuid }),
               let jsonData = try? JSONSerialization.data(withJSONObject: episode),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }

        return nil
    }
}

public enum TaskError: Error {
    case nilSelf
}
