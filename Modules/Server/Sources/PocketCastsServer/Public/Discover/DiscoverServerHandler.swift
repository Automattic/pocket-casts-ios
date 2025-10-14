import Combine
import Foundation
import PocketCastsUtils

public protocol DiscoverServerHandling {
    func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory]
}

public class DiscoverServerHandler: DiscoverServerHandling {
    enum DiscoverServerError: Error {
        case unknown
        case badRequest
    }

    public static let shared = DiscoverServerHandler()

    private let tokenHelper = {
        let connection = URLConnection(handler: URLSession.shared)
        return TokenHelper(urlConnection: connection)
    }()

    public private(set) lazy var discoveryCache: URLCache = {
        let cache = URLCache(memoryCapacity: 1024 * 1024, diskCapacity: 5 * 1024 * 1024, diskPath: "discovery")
        return cache
    }()

    /**
     * Valid image sizes: 130,140,200,210,280,340,400,420,680,960
     */
    public class func thumbnailUrl(forPodcast podcast: String, size: Int) -> URL {
        let urlString = thumbnailUrlString(forPodcast: podcast, size: size)

        return URL(string: urlString)!
    }

    public class func thumbnailUrlString(forPodcast podcast: String, size: Int) -> String {
        "\(ServerConstants.Urls.discover())images/\(size)/\(podcast).jpg"
    }

    public func discoverPage() async -> (DiscoverLayout?, Bool) {
        let contentPath: String
        if FeatureFlag.recommendations.enabled {
            contentPath = "ios/content_v3.json"
        } else {
            contentPath = "ios/content_v2.json"
        }
        return await withCheckedContinuation { continuation in
            discoverRequest(path: ServerConstants.Urls.discover() + contentPath, type: DiscoverLayout.self, authenticated: nil) { discoverItems, cachedResponse in
                continuation.resume(returning: (discoverItems, cachedResponse))
            }
        }
    }

    public func discoverPage(completion: @escaping (DiscoverLayout?, Bool) -> Void) {
        Task {
            let page = await discoverPage()
            completion(page.0, page.1)
        }
    }

    public func discoverNetworkList(source: String, authenticated: Bool?, completion: @escaping ([PodcastNetwork]?) -> Void) {
        discoverRequest(path: source, type: [PodcastNetwork].self, authenticated: authenticated) { networkList, _ in
            completion(networkList)
        }
    }

    public func discoverPodcastList(source: String, authenticated: Bool?, completion: @escaping (PodcastList?) -> Void) {
        discoverRequest(path: source, type: PodcastList.self, authenticated: authenticated) { podcastList, _ in
            completion(podcastList)
        }
    }

    public func discoverCategories(source: String, authenticated: Bool?, completion: @escaping ([DiscoverCategory]?) -> Void) {
        discoverRequest(path: source, type: [DiscoverCategory].self, authenticated: authenticated) { categories, _ in
            completion(categories)
        }
    }

    public func discoverCategories(source: String, authenticated: Bool?) async -> [DiscoverCategory] {
        await withCheckedContinuation { continuation in
            discoverCategories(source: source, authenticated: authenticated) { result in
                continuation.resume(returning: result ?? [])
            }
        }
    }

    public func discoverCategoryDetails(source: String, authenticated: Bool?, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        discoverRequest(path: source, type: DiscoverCategoryDetails.self, authenticated: authenticated) { categoryDetails, _ in
            completion(categoryDetails)
        }
    }

    public func discoverCategoryDetails(source: String, authenticated: Bool?) async -> DiscoverCategoryDetails? {
        await withCheckedContinuation { continuation in
            discoverCategoryDetails(source: source, authenticated: authenticated) { result in
                continuation.resume(returning: result)
            }
        }
    }

    public func discoverPodcastCollection(source: String, authenticated: Bool?, completion: @escaping (PodcastCollection?) -> Void) {
        discoverRequest(path: source, type: PodcastCollection.self, authenticated: authenticated) { podcastCollection, _ in
            completion(podcastCollection)
        }
    }

    public func discoverItem<T>(_ source: String?, authenticated: Bool, type: T.Type) -> AnyPublisher<T, Error> where T: Decodable {
        guard let source = source else {
            return Fail(error: DiscoverServerError.badRequest).eraseToAnyPublisher()
        }

        return Future { [unowned self] promise in
            self.discoverRequest(path: source, type: type, authenticated: authenticated) { discoverList, didError in
                if !didError, let discoverList = discoverList {
                    promise(.success(discoverList))
                } else {
                    promise(.failure(DiscoverServerError.unknown))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// A method to check whether the response from the source URL authenticated successfully.
    /// - Parameters:
    ///   - item: An item which is `authenticated == true`
    /// - Returns: Whether or not the authentication succeeded
    public func checkSourceAuthentication(for item: DiscoverItem) async -> Bool {
        // If there's no source URL, consider authentication failed. This shouldn't happen.
        guard item.isAuthenticated, let source = item.source else {
            return false
        }

        return await withCheckedContinuation { continuation in
            performDiscoverRequest(path: source, authenticated: item.isAuthenticated) { data, response, error, _ in
                let success = response?.extractStatusCode() == 200
                continuation.resume(returning: success)
            }
        }
    }

    public func cachedResponse(for path: String) -> CachedURLResponse? {
        let url = ServerHelper.asUrl(path)
        let request = URLRequest(url: url)
        if let cachedResponse = discoveryCache.cachedResponse(for: request),
           let expiryDate = cachedResponse.response.cacheExpiryDate(),
           expiryDate.timeIntervalSinceNow > 0 {
            return cachedResponse
        }
        return nil
    }

    private func performDiscoverRequest(
        path: String,
        authenticated: Bool?,
        completion: @escaping (Data?, URLResponse?, Error?, Bool) -> Void
    ) {
        let url = ServerHelper.asUrl(path)
        var request = URLRequest(url: url)
        request.addLocalizationHeaders()

        if let cachedResponse = cachedResponse(for: path) {
            completion(cachedResponse.data, cachedResponse.response, nil, true)
            return
        }

        if FeatureFlag.recommendations.enabled && authenticated == true {
            tokenHelper.callSecureUrl(request: request) { response, data, error in
                completion(data, response, error, false)
            }
        } else {
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                completion(data, response, error, false)
            }).resume()
        }
    }

    private func decodeDiscoverResponse<T>(
        data: Data,
        response: URLResponse,
        cacheRequest: URLRequest,
        useCache: Bool,
        type: T.Type
    ) -> T? where T: Decodable {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let decoded = try decoder.decode(type, from: data)
            if useCache {
                let responseToCache = CachedURLResponse(response: response, data: data)
                discoveryCache.storeCachedResponse(responseToCache, for: cacheRequest)
            }
            return decoded
        } catch {
            if useCache {
                discoveryCache.removeCachedResponse(for: cacheRequest)
            }
            return nil
        }
    }

    func discoverRequest<T>(
        path: String,
        type: T.Type,
        authenticated: Bool?,
        completion: @escaping (T?, Bool) -> Void
    ) where T: Decodable {
        let url = ServerHelper.asUrl(path)
        let request = URLRequest(url: url)

        performDiscoverRequest(path: path, authenticated: authenticated) { [weak self] data, response, error, useCache in
            guard
                let self = self,
                let data = data,
                let response = response,
                error == nil
            else {
                completion(nil, false)
                return
            }

            let decoded = self.decodeDiscoverResponse(
                data: data,
                response: response,
                cacheRequest: request,
                useCache: true,
                type: type
            )
            completion(decoded, useCache)
        }
    }
}
