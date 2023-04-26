import Foundation
import Kingfisher

/// Extracts artwork from a streaming episode (if there's any)
class StreamingEpisodeArtwork {
    private let imageManager: ImageManager

    init(imageManager: ImageManager = .sharedManager) {
        self.imageManager = imageManager
    }

    /// Extract a UIImage from a given asset if embedded artwork option is enabled.
    /// If an image is extracted, `episodeEmbeddedArtworkLoaded` notification is triggered
    /// - Parameters:
    ///   - asset: an AVAsset
    ///   - episodeUuid: the UUID of the current playing episode
    func loadEmbeddedImage(asset: AVAsset, episodeUuid: String) {
        guard Settings.loadEmbeddedImages, !isCached(episodeUuid: episodeUuid) else {
            return
        }

        let artworkItems = AVMetadataItem.metadataItems(from: asset.commonMetadata, filteredByIdentifier: .commonIdentifierArtwork)
        let image = artworkItems.compactMap { $0.dataValue.flatMap { UIImage(data: $0) } }.first

        guard let image else { return }

        set(for: episodeUuid, image: image) {
            NotificationCenter.postOnMainThread(notification: .episodeEmbeddedArtworkLoaded)
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
