import Foundation
import Kingfisher

/// Extracts artwork from a streaming episode (if there's any)
class StreamingEpisodeArtwork {
    static let shared = StreamingEpisodeArtwork()

    private lazy var subscribedPodcastsCache: ImageCache = {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/artworkv3")
        let url = URL(fileURLWithPath: path)
        subscribedPodcastsCache = try! ImageCache(name: "subscribedPodcastsCache", cacheDirectoryURL: url)
        subscribedPodcastsCache.diskStorage.config.sizeLimit = UInt(400.megabytes)
        subscribedPodcastsCache.diskStorage.config.expiration = .days(365)
        return subscribedPodcastsCache
    }()

    /// Extract a UIImage from a given asset if embedded artwork option is enabled.
    /// If an image is extracted, `episodeEmbeddedArtworkLoaded` notification is triggered
    /// - Parameters:
    ///   - asset: an AVAsset
    ///   - episodeUuid: the UUID of the current playing episode
    func loadEmbeddedImage(asset: AVAsset, episodeUuid: String) {
        guard Settings.loadEmbeddedImages, !isCached(episodeUuid: episodeUuid) else {
            return
        }

        let metadata = asset.metadata
        for item in metadata {
            if let key = item.commonKey?.rawValue, key == "artwork" {
                if let imageData = item.value as? Data {
                    let image = UIImage(data: imageData)

                    if let image {
                        set(for: episodeUuid, image: image) {
                            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeEmbeddedArtworkLoaded)
                        }
                    }

                }
            }
        }
    }

    func get(for episodeUuid: String, completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?) {
        subscribedPodcastsCache.retrieveImage(forKey: episodeUuid, options: .none, completionHandler: completionHandler)
    }

    func isCached(episodeUuid: String) -> Bool {
        subscribedPodcastsCache.isCached(forKey: episodeUuid)
    }

    private func set(for episodeUuid: String, image: UIImage, completion: (() -> Void)?) {
        subscribedPodcastsCache.store(image, forKey: episodeUuid) { _ in
            completion?()
        }
    }
}
