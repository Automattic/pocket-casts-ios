import Foundation
import PocketCastsDataModel
import PocketCastsUtils
#if os(watchOS)
    import WatchKit
#else
    import UIKit
#endif

protocol BaseRequest: Encodable {
    var device: String? { get set }
    var m: String? { get set }
    var av: String? { get set }
    var l: String? { get set }
    var c: String? { get set }
    var dt: String? { get set }
    var v: String? { get set }
}

public class MainServerHandler {
    private static let callTimeout = 60.seconds

    public static let shared = MainServerHandler()

    private static let parserVersion = "1.7"
    private static let deviceType = "1"

    private lazy var securityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"

        return formatter
    }()

    private lazy var searchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    struct PodcastSearchQuery: BaseRequest {
        var q: String?
        var dt: String?
        var device: String?
        var v: String?
        var m: String?
        var av: String?
        var l: String?
        var c: String?
    }

    private struct PodcastUuidSearchQuery: BaseRequest {
        var id: Int?
        var dt: String?
        var device: String?
        var v: String?
        var m: String?
        var av: String?
        var l: String?
        var c: String?
    }

    private struct ShareListRequest: BaseRequest {
        var dt: String?
        var device: String?
        var v: String?
        var m: String?
        var av: String?
        var l: String?
        var c: String?
    }

    private struct ExportPodcastsRequest: BaseRequest {
        var uuids: [String]?
        var device: String?
        var m: String?
        var av: String?
        var l: String?
        var c: String?
        var dt: String?
        var v: String?
    }

    private struct UploadOpmlRequest: BaseRequest {
        var urls: [String]?
        var pollUuids: [String]?
        var device: String?
        var m: String?
        var av: String?
        var l: String?
        var c: String?
        var dt: String?
        var v: String?

        public enum CodingKeys: String, CodingKey {
            case urls, pollUuids = "poll_uuids", device, m, av, l, c, dt, v
        }
    }

    public func sendOpmlChunk(feedUrls: [String] = [], pollUuids: [String] = [], completion: @escaping (ImportOpmlResponse?) -> Void) {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            completion(ImportOpmlResponse.failedResponse())
            return
        }

        var baseRequest: BaseRequest = UploadOpmlRequest()
        addStandardParams(baseRequest: &baseRequest, uniqueId: uniqueId)

        var uploadRequest = baseRequest as! UploadOpmlRequest
        uploadRequest.urls = feedUrls
        uploadRequest.pollUuids = pollUuids

        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "import/opml")
        guard let request = ServerHelper.createJsonRequest(url: url, params: uploadRequest, timeout: MainServerHandler.callTimeout, cachePolicy: .reloadIgnoringCacheData) else {
            completion(ImportOpmlResponse.failedResponse())
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(ImportOpmlResponse.failedResponse())
                return
            }

            do {
                let refreshResponse = try JSONDecoder().decode(ImportOpmlResponse.self, from: data)
                completion(refreshResponse)
            } catch {
                completion(ImportOpmlResponse.failedResponse())
            }

        }.resume()
    }

    public func exportPodcasts(uuids: [String], completion: @escaping (ExportPodcastsResponse?) -> Void) {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            completion(ExportPodcastsResponse.failedResponse())
            return
        }

        var baseRequest: BaseRequest = ExportPodcastsRequest()
        addStandardParams(baseRequest: &baseRequest, uniqueId: uniqueId)

        var exportRequest = baseRequest as! ExportPodcastsRequest
        exportRequest.uuids = uuids

        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "import/export_feed_urls")
        guard let request = ServerHelper.createJsonRequest(url: url, params: exportRequest, timeout: MainServerHandler.callTimeout, cachePolicy: .reloadIgnoringCacheData) else {
            completion(ExportPodcastsResponse.failedResponse())
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(ExportPodcastsResponse.failedResponse())
                return
            }

            do {
                let refreshResponse = try JSONDecoder().decode(ExportPodcastsResponse.self, from: data)
                completion(refreshResponse)
            } catch {
                completion(ExportPodcastsResponse.failedResponse())
            }

        }.resume()
    }

    public func lookupShareLink(sharePath: String, completion: @escaping (ShareListResponse?) -> Void) {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            completion(ShareListResponse.failedResponse())
            return
        }

        var shareLinkRequest: BaseRequest = ShareListRequest()
        addStandardParams(baseRequest: &shareLinkRequest, uniqueId: uniqueId)

        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + sharePath)
        guard let request = ServerHelper.createJsonRequest(url: url, params: shareLinkRequest as! ShareListRequest, timeout: MainServerHandler.callTimeout, cachePolicy: .reloadIgnoringCacheData) else {
            completion(ShareListResponse.failedResponse())
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(ShareListResponse.failedResponse())
                return
            }

            do {
                let refreshResponse = try JSONDecoder().decode(ShareListResponse.self, from: data)
                completion(refreshResponse)
            } catch {
                completion(ShareListResponse.failedResponse())
            }

        }.resume()
    }

    public func refresh(podcasts: [Podcast], completion: @escaping (PodcastRefreshResponse?) -> Void) {
        guard let request = createRefreshRequest(podcasts: podcasts) else {
            completion(PodcastRefreshResponse.failedResponse())
            return
        }

        TokenHelper.callSecureUrl(request: request) { response, data, error in
            let statusCode = response?.statusCode ?? 0

            guard statusCode == ServerConstants.HttpConstants.ok, let data = data else {
                if let error = error {
                    FileLog.shared.addMessage("Refresh failed: with error \(error.localizedDescription), status code \(statusCode)")
                } else {
                    FileLog.shared.addMessage("Refresh failed: response returned no data, status code \(statusCode)")
                }
                completion(PodcastRefreshResponse.failedResponse())
                return
            }

            let refreshResponse = ServerHelper.decodeRefreshResponse(from: data)
            completion(refreshResponse)
        }
    }

    public func createRefreshRequest(podcasts: [Podcast]) -> URLRequest? {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            return nil
        }

        for podcast in podcasts { // ensure podcasts have up to date latest episode uuids
            ServerPodcastManager.shared.updateLatestEpisodeInfo(podcast: podcast, setDefaults: false)
        }

        let pushEnabled = ServerConfig.shared.syncDelegate?.isPushEnabled() ?? false

        var jsonRequest = jsonWithStandardParams(uniqueId: uniqueId)
        jsonRequest["push_sound"] = "11" // for legacy reasons, this is always the push sound we send, since it's no longer configurable
        jsonRequest["podcasts"] = podcasts.map(\.uuid).joined(separator: ",")
        jsonRequest["last_episodes"] = podcasts.map { $0.forceRefreshEpisodeFrom ?? $0.latestEpisodeUuid ?? "" }.joined(separator: ",")
        jsonRequest["push_messages_on"] = podcasts.map { (pushEnabled && $0.pushEnabled) ? "1" : "0" }.joined()
        if let pushToken = ServerSettings.pushToken() {
            jsonRequest["push_token"] = pushToken
        }
        jsonRequest["push_on"] = pushEnabled ? "true" : "false"
        guard let data = try? JSONSerialization.data(withJSONObject: jsonRequest, options: []) else {
            FileLog.shared.addMessage("Failed to create refresh request")
            return nil
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "user/update")
        let request = ServerHelper.createJsonRequest(url: url, data: data, timeout: MainServerHandler.callTimeout, cachePolicy: .reloadIgnoringCacheData)

        return request
    }

    public func podcastSearch(searchTerm: String, completion: @escaping (PodcastSearchResponse?) -> Void) {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            completion(PodcastSearchResponse.failedResponse())
            return
        }

        var baseQuery: BaseRequest = PodcastSearchQuery()
        addStandardParams(baseRequest: &baseQuery, uniqueId: uniqueId)

        var searchQuery = baseQuery as! PodcastSearchQuery
        searchQuery.q = searchTerm

        let searchOperation = PodcastSearchOperation(searchQuery: searchQuery, completionHandler: completion)
        searchQueue.addOperation(searchOperation)
    }

    func podcastSearchQuery(searchTerm: String) -> PodcastSearchQuery? {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            return nil
        }

        var baseQuery: BaseRequest = PodcastSearchQuery()
        addStandardParams(baseRequest: &baseQuery, uniqueId: uniqueId)

        var searchQuery = baseQuery as! PodcastSearchQuery
        searchQuery.q = searchTerm

        return searchQuery
    }

    public func refreshPodcastFeed(podcast: Podcast, completion: @escaping (Bool) -> Void) {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            completion(false)

            return
        }

        var jsonRequest = jsonWithStandardParams(uniqueId: uniqueId)
        jsonRequest["podcast_uuid"] = podcast.uuid
        guard let data = try? JSONSerialization.data(withJSONObject: jsonRequest, options: []) else {
            FileLog.shared.addMessage("Failed to create refreshPodcastFeed request")
            completion(false)

            return
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "podcasts/refresh")
        let request = ServerHelper.createJsonRequest(url: url, data: data, timeout: MainServerHandler.callTimeout, cachePolicy: .reloadIgnoringCacheData)
        FileLog.shared.addMessage("Attempting to refresh podcast feed for \(podcast.uuid)")
        URLSession.shared.dataTask(with: request) { _, response, error in
            guard let response = response as? HTTPURLResponse, response.statusCode == ServerConstants.HttpConstants.ok else {
                FileLog.shared.addMessage("Feed refresh failed: \(error?.localizedDescription ?? "No error")")
                completion(false)

                return
            }

            FileLog.shared.addMessage("Server indicated podcast refresh was successful")
            completion(true)

        }.resume()
    }

    public func findPodcastByiTunesId(_ iTunesId: Int, completion: @escaping (String?) -> Void) {
        guard let uniqueId = ServerConfig.shared.syncDelegate?.uniqueAppId() else {
            completion(nil)
            return
        }

        var baseQuery: BaseRequest = PodcastUuidSearchQuery()
        addStandardParams(baseRequest: &baseQuery, uniqueId: uniqueId)

        var searchQuery = baseQuery as! PodcastUuidSearchQuery
        searchQuery.id = iTunesId

        let url = ServerHelper.asUrl(ServerConstants.Urls.main() + "podcasts/show")
        guard let request = ServerHelper.createJsonRequest(url: url, params: searchQuery, timeout: MainServerHandler.callTimeout, cachePolicy: .useProtocolCachePolicy) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(PodcastSearchResponse.self, from: data)
                completion(searchResponse.result?.podcast?.uuid)
            } catch {
                completion(nil)
            }

        }.resume()
    }

    private func jsonWithStandardParams(uniqueId: String) -> [String: Any] {
        var json: [String: Any] = [:]
        let locale = Locale.current
        json["l"] = locale.languageCode
        json["c"] = locale.regionCode

        #if os(watchOS)
            json["m"] = WKInterfaceDevice.current().systemVersion
        #else
            json["m"] = UIDevice.current.systemVersion
        #endif

        json["dt"] = MainServerHandler.deviceType
        json["v"] = MainServerHandler.parserVersion
        json["device"] = uniqueId
        json["av"] = ServerConfig.shared.syncDelegate?.appVersion()

        return json
    }

    private func addStandardParams(baseRequest: inout BaseRequest, uniqueId: String) {
        let locale = Locale.current
        baseRequest.l = locale.languageCode
        baseRequest.c = locale.regionCode

        #if os(watchOS)
            baseRequest.m = WKInterfaceDevice.current().systemVersion
        #else
            baseRequest.m = UIDevice.current.systemVersion
        #endif

        baseRequest.dt = MainServerHandler.deviceType
        baseRequest.v = MainServerHandler.parserVersion
        baseRequest.device = uniqueId
        baseRequest.av = ServerConfig.shared.syncDelegate?.appVersion()
    }
}
