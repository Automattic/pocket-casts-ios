import Combine
import Foundation
import PocketCastsUtils

public class DiscoverServerHandler {
    enum DiscoverServerError: Error {
        case unknown
        case badRequest
    }

    public static let shared = DiscoverServerHandler()

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

    public func discoverPage(completion: @escaping (DiscoverLayout?, Bool) -> Void) {
        let contentPath: String
        if FeatureFlag.recommendations.enabled {
            contentPath = "ios/content_v3.json"
        } else {
            contentPath = "ios/content_v2.json"
        }
        discoverRequest(path: ServerConstants.Urls.discover() + contentPath, type: DiscoverLayout.self, authenticated: nil) { discoverItems, cachedResponse in
            completion(discoverItems, cachedResponse)
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
        return await withCheckedContinuation { continuation in
            DiscoverServerHandler.shared.discoverCategories(source: source, authenticated: authenticated, completion: { discoverCategories in
                DispatchQueue.main.async {
                    guard let discoverCategories = discoverCategories else {
                        continuation.resume(returning: [])
                        return
                    }
                    continuation.resume(returning: discoverCategories)
                }
            })
        }
    }

    public func discoverCategoryDetails(source: String, authenticated: Bool?, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        discoverRequest(path: source, type: DiscoverCategoryDetails.self, authenticated: authenticated) { categoryDetails, _ in
            completion(categoryDetails)
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

    private let tokenHelper = {
        let connection = URLConnection(handler: URLSession.shared)
        return TokenHelper(urlConnection: connection)
    }()

    private func discoverRequest<T>(path: String, type: T.Type, authenticated: Bool?, completion: @escaping (T?, Bool) -> Void) where T: Decodable {
        let url = ServerHelper.asUrl(path)
        let request = URLRequest(url: url)

        if let cachedResponse = discoveryCache.cachedResponse(for: request) {
            if let expiryDate = cachedResponse.response.cacheExpiryDate(), expiryDate.timeIntervalSinceNow > 0 {
                do {
                    let list = try JSONDecoder().decode(type, from: cachedResponse.data)
                    completion(list, true)

                    return
                } catch {
                    discoveryCache.removeCachedResponse(for: request)
                }
            }
        }

        let completion: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
            guard let data = data, let response = response, error == nil else {
                completion(nil, false)
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let list = try decoder.decode(type, from: data)
                completion(list, false)

                // only cache successful responses
                let responseToCache = CachedURLResponse(response: response, data: data)
                self?.discoveryCache.storeCachedResponse(responseToCache, for: request)
            } catch {
                completion(nil, false)
            }
        }

        if FeatureFlag.recommendations.enabled && authenticated == true {
            tokenHelper.callSecureUrl(request: request) { response, data, error in
                completion(data, response, error)
            }
        } else {
            URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
        }
    }
}
