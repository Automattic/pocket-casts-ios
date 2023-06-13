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
    func loadEmbeddedImage(asset: AVAsset?, podcastUuid: String, episodeUuid: String) {
        guard Settings.loadEmbeddedImages, !isCached(episodeUuid: episodeUuid) else {
            return
        }

        if let assetEpisodeArtwork = loadEpisodeArtwork(from: asset) {
            save(assetEpisodeArtwork, for: episodeUuid)
            return
        }

        loadEpisodeArtworkFromUrl(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
    }

    func isCached(episodeUuid: String) -> Bool {
        imageManager.subscribedPodcastsCache.isCached(forKey: episodeUuid)
    }

    private func loadEpisodeArtwork(from asset: AVAsset?) -> UIImage? {
        guard let asset else {
            return nil
        }

        let artworkItems = AVMetadataItem.metadataItems(from: asset.commonMetadata, filteredByIdentifier: .commonIdentifierArtwork)
        return artworkItems.compactMap { $0.dataValue.flatMap { UIImage(data: $0) } }.first
    }

    private func loadEpisodeArtworkFromUrl(podcastUuid: String, episodeUuid: String) {
        CacheServerHandler.shared.loadEpisodeArtworkUrl(podcastUuid: podcastUuid, episodeUuid: episodeUuid) { [weak self] imageUrl in
            guard let self else {
                return
            }

            if let imageUrl, let url = URL(string: imageUrl) {
                KingfisherManager.shared.retrieveImage(with: url, options: [.targetCache(self.imageManager.subscribedPodcastsCache)]) { result in
                    if let image = try? result.get().image {
                        self.save(image, for: episodeUuid)
                    }
                }
            }
        }
    }

    private func save(_ image: UIImage, for episodeUuid: String) {
        imageManager.subscribedPodcastsCache.store(image, forKey: episodeUuid) { _ in
            NotificationCenter.postOnMainThread(notification: .episodeEmbeddedArtworkLoaded)
        }
    }
}
