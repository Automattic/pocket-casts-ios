import Combine
import Foundation
import PocketCastsUtils

public class DiscoverServerHandler {
    enum DiscoverServerError: Error {
        case unknown
        case badRequest
    }

    public static let shared = DiscoverServerHandler()

    private lazy var discoveryCache: URLCache = {
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
        if FeatureFlag.categoriesRedesign.enabled {
            contentPath = "ios/content_v2.json"
        } else {
            contentPath = "ios/content.json"
        }

        discoverRequest(path: ServerConstants.Urls.discover() + contentPath, type: DiscoverLayout.self) { discoverItems, cachedResponse in
            completion(discoverItems, cachedResponse)
        }
    }

    public func discoverNetworkList(source: String, completion: @escaping ([PodcastNetwork]?) -> Void) {
        discoverRequest(path: source, type: [PodcastNetwork].self) { networkList, _ in
            completion(networkList)
        }
    }

    public func discoverPodcastList(source: String, completion: @escaping (PodcastList?) -> Void) {
        discoverRequest(path: source, type: PodcastList.self) { podcastList, _ in
            completion(podcastList)
        }
    }

    public func discoverCategories(source: String, completion: @escaping ([DiscoverCategory]?) -> Void) {
        discoverRequest(path: source, type: [DiscoverCategory].self) { categories, _ in
            completion(categories)
        }
    }

    public func discoverCategories(source: String) async -> [DiscoverCategory] {
        return await withCheckedContinuation { continuation in
            DiscoverServerHandler.shared.discoverCategories(source: source, completion: { discoverCategories in
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

    public func discoverCategoryDetails(source: String, completion: @escaping (DiscoverCategoryDetails?) -> Void) {
        discoverRequest(path: source, type: DiscoverCategoryDetails.self) { categoryDetails, _ in
            completion(categoryDetails)
        }
    }

    public func discoverPodcastCollection(source: String, completion: @escaping (PodcastCollection?) -> Void) {
        discoverRequest(path: source, type: PodcastCollection.self) { podcastCollection, _ in
            completion(podcastCollection)
        }
    }

    public func discoverItem<T>(_ source: String?, type: T.Type) -> AnyPublisher<T, Error> where T: Decodable {
        guard let source = source else {
            return Fail(error: DiscoverServerError.badRequest).eraseToAnyPublisher()
        }

        return Future { [unowned self] promise in
            self.discoverRequest(path: source, type: type) { discoverList, didError in
                if !didError, let discoverList = discoverList {
                    promise(.success(discoverList))
                } else {
                    promise(.failure(DiscoverServerError.unknown))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func discoverRequest<T>(path: String, type: T.Type, completion: @escaping (T?, Bool) -> Void) where T: Decodable {
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

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
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
        }.resume()
    }
}
