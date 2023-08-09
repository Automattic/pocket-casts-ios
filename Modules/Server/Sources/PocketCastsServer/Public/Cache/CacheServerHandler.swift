import Foundation
import PocketCastsDataModel

public class CacheServerHandler {
    private static let defaultTimeout: TimeInterval = 15

    public static let shared = CacheServerHandler()

    public static let noShowNotesMessage = "Unable to find show notes for this episode."

    private let showNotesUrlCache: URLCache
    private let colorsUrlsCache: URLCache

    private lazy var episodeInfoHandler = EpisodeInfoHandler()

    public static var newShowNotesEndpoint: Bool = false

    public init() {
        showNotesUrlCache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "show_notes")
        colorsUrlsCache = URLCache(memoryCapacity: 400.kilobytes, diskCapacity: 5.megabytes, diskPath: "colors")
    }

    // MARK: - Show Notes

    public func loadShowNotes(podcastUuid: String, episodeUuid: String, cached: ((String) -> Void)? = nil, completion: ((String?) -> Void)?) {
        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/episode/show_notes/\(episodeUuid)")
        let request = URLRequest(url: url)

        var cachedNotes = ""
        var didSendCachedNotes = false
        if let cachedResponse = showNotesUrlCache.cachedResponse(for: request), let showNotes = topLevelValue(data: cachedResponse.data, name: "show_notes", ofType: String.self) {
            cachedNotes = showNotes
            cached?(showNotes)
            didSendCachedNotes = true
        }

        TokenHelper.callSecureUrl(request: request) { [weak self] response, data, _ in
            guard let strongSelf = self else { return }

            if let data = data, let response = response, let showNotes = strongSelf.topLevelValue(data: data, name: "show_notes", ofType: String.self) {
                let responseToCache = CachedURLResponse(response: response, data: data)
                strongSelf.showNotesUrlCache.storeCachedResponse(responseToCache, for: request)

                if didSendCachedNotes, showNotes == cachedNotes {
                    return
                }
                completion?(showNotes)
            } else if !didSendCachedNotes {
                // if loading failed and we haven't sent the client anything, send it a message it can show the user instead
                completion?(CacheServerHandler.noShowNotesMessage)
            }
        }
    }

    public func loadPodcastColors(podcastUuid: String, allowCachedVersion: Bool, completion: @escaping ((String?, String?, String?) -> Void)) {
        let url = ServerHelper.colorUrl(podcastUuid: podcastUuid)
        var request = URLRequest(url: url)
        if !allowCachedVersion {
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }

        var sentResponse = false
        if allowCachedVersion, let cachedResponse = colorsUrlsCache.cachedResponse(for: request) {
            extractCachedColors(responseData: cachedResponse.data, completion: completion)
            sentResponse = true
        }

        // even after returning a cached response, we still go and check if there's a newer version available and if so put that in our cache for next time
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let strongSelf = self else { return }

            if let data = data, let response = response {
                let responseToCache = CachedURLResponse(response: response, data: data)
                strongSelf.colorsUrlsCache.storeCachedResponse(responseToCache, for: request)

                if !sentResponse {
                    strongSelf.extractCachedColors(responseData: data, completion: completion)
                }
            }
        }.resume()
    }

    private func extractCachedColors(responseData: Data, completion: (String?, String?, String?) -> Void) {
        do {
            let jsonDictionary = try JSONSerialization.jsonObject(with: responseData, options: [] as JSONSerialization.ReadingOptions) as? NSDictionary

            if let colors = jsonDictionary?["colors"] as? [String: String], let backgroundColor = colors["background"], let lightThemeTint = colors["tintForLightBg"], let darkThemeTint = colors["tintForDarkBg"] {
                completion(backgroundColor, lightThemeTint, darkThemeTint)

                return
            }
        } catch {}

        completion(nil, nil, nil)
    }

    // MARK: - Podcast Info

    public func loadPodcastInfo(podcastUuid: String, completion: @escaping (([String: Any]?, String?) -> Void)) {
        let url = urlForPodcast(uuid: podcastUuid)
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: CacheServerHandler.defaultTimeout)

        TokenHelper.callSecureUrl(request: request) { [weak self] response, data, _ in
            guard let strongSelf = self else { return }

            if response?.statusCode == ServerConstants.HttpConstants.ok, let data = data, let podcastInfo = strongSelf.asJson(data: data) {
                if let lastModified = response?.allHeaderFields[ServerConstants.HttpHeaders.lastModified] as? String {
                    completion(podcastInfo, lastModified)
                } else {
                    completion(podcastInfo, nil)
                }

                return
            }

            completion(nil, nil)
        }
    }

    public func loadEpisodeUrl(episodeUuid: String, podcastUuid: String, completion: @escaping ((String?) -> Void)) {
        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/episode/url/\(podcastUuid)/\(episodeUuid)")
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: CacheServerHandler.defaultTimeout)

        TokenHelper.callSecureUrl(request: request) { response, data, _ in
            if response?.statusCode == ServerConstants.HttpConstants.ok, let data = data, let url = String(data: data, encoding: .utf8) {
                completion(url)

                return
            }

            completion(nil)
        }
    }

    public func loadPodcastIfModified(podcast: Podcast, completion: @escaping (([String: Any]?, String?) -> Void)) {
        let url = urlForPodcast(uuid: podcast.uuid)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: CacheServerHandler.defaultTimeout)
        if let lastUpdated = podcast.lastUpdatedAt, podcast.isSubscribed() {
            request.setValue(lastUpdated, forHTTPHeaderField: ServerConstants.HttpHeaders.ifModifiedSince)
        }

        TokenHelper.callSecureUrl(request: request) { [weak self] response, data, _ in
            // podcast hasn't changed
            if response?.statusCode == ServerConstants.HttpConstants.notModified {
                completion(nil, nil)
                return
            }

            guard let strongSelf = self else { return }
            if let data = data, let podcastInfo = strongSelf.asJson(data: data) {
                if let lastModified = response?.allHeaderFields[ServerConstants.HttpHeaders.lastModified] as? String {
                    completion(podcastInfo, lastModified)
                } else {
                    completion(podcastInfo, nil)
                }
                return
            }

            completion(nil, nil)
        }
    }

    // MARK: - Episode Search

    public struct EpisodeSearchQuery: Codable {
        let podcastuuid: String
        let searchterm: String

        public init(podcastUuid: String, searchTerm: String) {
            podcastuuid = podcastUuid
            searchterm = searchTerm
        }
    }

    public struct EpisodeSearchResult: Codable {
        public let episodes: [SearchResultEpisodes]
    }

    public struct SearchResultEpisodes: Codable {
        public let uuid: String
    }

    public func searchEpisodesInPodcast(search: EpisodeSearchQuery, completion: ((EpisodeSearchResult?) -> Void)?) {
        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/podcast/episode/search")
        guard let request = ServerHelper.createJsonRequest(url: url, params: search, timeout: CacheServerHandler.defaultTimeout, cachePolicy: .useProtocolCachePolicy) else {
            completion?(nil)

            return
        }

        TokenHelper.callSecureUrl(request: request) { response, data, _ in
            guard response?.statusCode == ServerConstants.HttpConstants.ok, let data = data else {
                completion?(nil)
                return
            }

            do {
                let searchResults = try JSONDecoder().decode(EpisodeSearchResult.self, from: data)
                completion?(searchResults)
            } catch {
                completion?(nil)
            }
        }
    }

    // MARK: - Helper Methods

    private func urlForPodcast(uuid: String) -> URL {
        ServerHelper.asUrl("\(ServerConstants.Urls.cache())mobile/podcast/full/\(uuid)")
    }

    private func topLevelValue<T>(data: Data?, name: String, ofType: T.Type) -> T? {
        guard let data = data else { return nil }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonDict = json as? [String: Any], let value = jsonDict[name] as? T {
                return value
            }
        } catch {}

        return nil
    }

    private func asJson(data: Data?) -> [String: Any]? {
        guard let data = data else { return nil }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] { return json }
        } catch {}

        return nil
    }
}
