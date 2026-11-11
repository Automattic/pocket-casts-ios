import Foundation
import PocketCastsDataModel
import PocketCastsUtils

public class CacheServerHandler {
    private static let defaultTimeout: TimeInterval = 15

    public static let shared = CacheServerHandler()

    public static let noShowNotesMessage = "Unable to find show notes for this episode."

    private let colorsUrlsCache: URLCache

    private let tokenHelper: TokenHelper

    private let urlConnection: URLConnection

    public convenience init() {
        self.init(tokenHelper: TokenHelper.shared)
    }

    init(tokenHelper: TokenHelper, urlConnection: URLConnection = URLConnection(handler: URLSession.shared)) {
        self.tokenHelper = tokenHelper
        self.urlConnection = urlConnection
        colorsUrlsCache = URLCache(memoryCapacity: 400.kilobytes, diskCapacity: 5.megabytes, diskPath: "colors")
    }

    // MARK: - Episode Artwork

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

            if let data, let response {
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

    /// Loads a podcast and its episodes, and the `Last-Modified` date of that list.
    ///
    /// - Parameter episodeListUrl: Where the podcast's episode list is, from ``loadEpisodeListUrls(podcastUuids:completion:)``.
    ///   When there is one, it's loaded directly instead of through the cache server's redirect. If that fails,
    ///   the podcast is loaded through the cache server.
    public func loadPodcastInfo(podcastUuid: String, episodeListUrl: URL? = nil, completion: @escaping (([String: Any]?, String?) -> Void)) {
        guard let episodeListUrl else {
            loadPodcastInfoFromCacheServer(podcastUuid: podcastUuid, completion: completion)
            return
        }

        loadEpisodeList(url: episodeListUrl) { podcastInfo, lastModified in
            if let podcastInfo {
                completion(podcastInfo, lastModified)
            } else {
                FileLog.shared.addMessage("CacheServerHandler: Couldn't load the episode list of \(podcastUuid) directly, loading it through the cache server")
                self.loadPodcastInfoFromCacheServer(podcastUuid: podcastUuid, completion: completion)
            }
        }
    }

    private func loadPodcastInfoFromCacheServer(podcastUuid: String, completion: @escaping (([String: Any]?, String?) -> Void)) {
        let url = url(forPodcastUuid: podcastUuid)
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: CacheServerHandler.defaultTimeout)
        request.addLocalizationHeaders()

        tokenHelper.callSecureUrl(request: request) { [weak self] response, data, _ in
            guard let strongSelf = self else { return }

            if response?.statusCode == ServerConstants.HttpConstants.ok, let data, let podcastInfo = strongSelf.asJson(data: data) {
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

    public func loadPodcastIfModified(podcast: Podcast, completion: @escaping (([String: Any]?, String?) -> Void)) {
        let url = url(forPodcastUuid: podcast.uuid)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: CacheServerHandler.defaultTimeout)
        if let lastUpdated = podcast.lastUpdatedAt, podcast.isSubscribed() {
            request.setValue(lastUpdated, forHTTPHeaderField: ServerConstants.HttpHeaders.ifModifiedSince)
        }
        request.addLocalizationHeaders()

        tokenHelper.callSecureUrl(request: request) { [weak self] response, data, _ in
            // podcast hasn't changed
            if response?.statusCode == ServerConstants.HttpConstants.notModified {
                completion(nil, nil)
                return
            }

            guard let strongSelf = self else { return }
            if let data, let podcastInfo = strongSelf.asJson(data: data) {
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

    // MARK: - Episode Lists

    private struct EpisodeListUrlsRequest: Encodable {
        let podcasts: [Podcast]

        struct Podcast: Encodable {
            let uuid: String
        }
    }

    private struct EpisodeListUrlsResponse: Decodable {
        let podcasts: [Podcast]

        struct Podcast: Decodable {
            let uuid: String
            let url: URL
        }
    }

    /// Looks up where each podcast's episode list is, in one request. These are the URLs that
    /// `mobile/podcast/full` redirects to. Podcasts the cache server can't find are left out, and
    /// a request that fails returns none.
    public func loadEpisodeListUrls(podcastUuids: [String], completion: @escaping ([String: URL]) -> Void) {
        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "podcasts/update")
        let params = EpisodeListUrlsRequest(podcasts: podcastUuids.map { EpisodeListUrlsRequest.Podcast(uuid: $0) })
        guard let request = ServerHelper.createJsonRequest(url: url, params: params, timeout: CacheServerHandler.defaultTimeout, cachePolicy: .reloadIgnoringLocalCacheData) else {
            completion([:])
            return
        }

        urlConnection.send(request: request) { data, response, error in
            guard (response as? HTTPURLResponse)?.statusCode == ServerConstants.HttpConstants.ok, let data,
                  let podcasts = try? JSONDecoder().decode(EpisodeListUrlsResponse.self, from: data).podcasts else {
                FileLog.shared.addMessage("CacheServerHandler: Couldn't look up the episode lists of \(podcastUuids.count) podcasts, status \((response as? HTTPURLResponse)?.statusCode ?? 0), error \(String(describing: error))")
                completion([:])
                return
            }

            completion(Dictionary(podcasts.map { ($0.uuid, $0.url) }, uniquingKeysWith: { first, _ in first }))
        }
    }

    private func loadEpisodeList(url: URL, completion: @escaping (([String: Any]?, String?) -> Void)) {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: CacheServerHandler.defaultTimeout)
        request.setValue(ServerConfig.shared.syncDelegate?.privateUserAgent(), forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)

        urlConnection.send(request: request) { [weak self] data, response, _ in
            guard let response = response as? HTTPURLResponse, response.statusCode == ServerConstants.HttpConstants.ok,
                  let podcastInfo = self?.asJson(data: data) else {
                completion(nil, nil)
                return
            }

            completion(podcastInfo, response.allHeaderFields[ServerConstants.HttpHeaders.lastModified] as? String)
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

        tokenHelper.callSecureUrl(request: request) { response, data, _ in
            guard response?.statusCode == ServerConstants.HttpConstants.ok, let data else {
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

    // MARK: - Bookmark Enrichment

    private struct BookmarkEnrichRequest: Encodable {
        let transcriptSnippet: String

        enum CodingKeys: String, CodingKey {
            case transcriptSnippet = "transcript_snippet"
        }
    }

    public struct BookmarkEnrichResponse: Decodable {
        public let title: String?
        public let summary: String?
        public let error: String?
    }

    /// Generates a title and summary for a bookmark from the transcript text surrounding its position.
    public func enrichBookmark(transcriptSnippet: String) async throws -> BookmarkEnrichResponse {
        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/bookmark/enrich")
        guard let request = ServerHelper.createJsonRequest(url: url, params: BookmarkEnrichRequest(transcriptSnippet: transcriptSnippet), timeout: CacheServerHandler.defaultTimeout, cachePolicy: .useProtocolCachePolicy) else {
            throw APIError.UNKNOWN
        }

        let (response, data) = try await tokenHelper.callSecureUrl(request: request)
        guard response?.statusCode == ServerConstants.HttpConstants.ok, let data else {
            throw APIError.UNKNOWN
        }

        return try JSONDecoder().decode(BookmarkEnrichResponse.self, from: data)
    }

    // MARK: - Helper Methods

    private func url(forPodcastUuid uuid: String) -> URL {
        ServerHelper.asUrl("\(ServerConstants.Urls.cache())mobile/podcast/full/\(uuid)")
    }

    private func asJson(data: Data?) -> [String: Any]? {
        guard let data else { return nil }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] { return json }
        } catch {}

        return nil
    }
}
