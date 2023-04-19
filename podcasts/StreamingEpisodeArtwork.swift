import Foundation
import Kingfisher

/// Extracts artwork from a streaming episode (if there's any)
class StreamingEpisodeArtwork {
    static let shared = StreamingEpisodeArtwork()

    /// Extract a UIImage from a given asset
    /// If an image is extracted, `episodeEmbeddedArtworkLoaded` notification is triggered
    /// - Parameters:
    ///   - asset: an AVAsset
    ///   - episodeUuid: the UUID of the current playing episode
    func loadEmbeddedImage(asset: AVAsset, episodeUuid: String) {
        // If it's already loaded and cached, do nothing
        let metadata = asset.metadata
        for item in metadata {
            if let key = item.commonKey?.rawValue, key == "artwork" {
                if let imageData = item.value as? Data {
                    let image = UIImage(data: imageData)

                    if let image {
                        EmbeddedArtworkCache.shared.set(for: episodeUuid, image: image) {
                            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeEmbeddedArtworkLoaded)
                        }
                    }

                }
            }
        }
    }
}


/// Saves the embedded artwork of a streaming episode
class EmbeddedArtworkCache {
    static let shared = EmbeddedArtworkCache()

    private var subscribedPodcastsCache: ImageCache

    private init() {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/artworkv3")
        let url = URL(fileURLWithPath: path)
        subscribedPodcastsCache = try! ImageCache(name: "subscribedPodcastsCache", cacheDirectoryURL: url)
        subscribedPodcastsCache.diskStorage.config.sizeLimit = UInt(400.megabytes)
        subscribedPodcastsCache.diskStorage.config.expiration = .days(365)
    }

    func set(for episodeUuid: String, image: UIImage, completion: (() -> Void)?) {
        subscribedPodcastsCache.store(image, forKey: episodeUuid) { _ in
            completion?()
        }
    }

    func get(for episodeUuid: String, completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?) {
        subscribedPodcastsCache.retrieveImage(forKey: episodeUuid, options: .none, completionHandler: completionHandler)
    }

    func isCache(episodeUuid: String) -> Bool {
        subscribedPodcastsCache.isCached(forKey: episodeUuid)
    }
}
