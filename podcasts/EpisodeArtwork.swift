import Foundation
import Kingfisher
import PocketCastsServer

/// Extracts artwork from a streaming episode (if there's any)
class EpisodeArtwork {
    private let imageManager: ImageManager

    init(imageManager: ImageManager = .sharedManager) {
        self.imageManager = imageManager
    }

    /// Attempts to load an episode embedded artwork.
    /// It first tries to load an embedded artwork from the AVAsset.
    /// If nothing is found, it then request the image from Cache Server Handler.
    /// If an image is retrieved, `episodeEmbeddedArtworkLoaded` notification is triggered
    /// - Parameters:
    ///   - asset: an AVAsset
    ///   - podcastUuid: the UUID of the current playing podcast
    ///   - episodeUuid: the UUID of the current playing episode
    func loadEmbeddedImage(asset: AVAsset, podcastUuid: String, episodeUuid: String) {
        guard Settings.loadEmbeddedImages, !isCached(episodeUuid: episodeUuid) else {
            return
        }

        let artworkItems = AVMetadataItem.metadataItems(from: asset.commonMetadata, filteredByIdentifier: .commonIdentifierArtwork)
        let image = artworkItems.compactMap { $0.dataValue.flatMap { UIImage(data: $0) } }.first

        if let image {
            set(for: episodeUuid, image: image) {
                NotificationCenter.postOnMainThread(notification: .episodeEmbeddedArtworkLoaded)
            }
        } else {
            CacheServerHandler.shared.loadEpisodeArtworkUrl(podcastUuid: podcastUuid, episodeUuid: episodeUuid) { [weak self] imageUrl in
                if let imageUrl, let url = URL(string: imageUrl) {
                    KingfisherManager.shared.retrieveImage(with: url, options: nil) { result in
                        if let image = try? result.get().image {
                            self?.set(for: episodeUuid, image: image) {
                                NotificationCenter.postOnMainThread(notification: .episodeEmbeddedArtworkLoaded)
                            }
                        }
                    }
                }
            }
        }
    }

    func isCached(episodeUuid: String) -> Bool {
        imageManager.subscribedPodcastsCache.isCached(forKey: episodeUuid)
    }

    private func set(for episodeUuid: String, image: UIImage, completion: (() -> Void)?) {
        imageManager.subscribedPodcastsCache.store(image, forKey: episodeUuid) { _ in
            completion?()
        }
    }
}
