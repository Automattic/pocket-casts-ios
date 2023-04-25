import Foundation
import Kingfisher

/// Extracts artwork from a streaming episode (if there's any)
class StreamingEpisodeArtwork {
    static let shared = StreamingEpisodeArtwork()

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
        ImageManager.sharedManager.subscribedPodcastsCache.isCached(forKey: episodeUuid)
    }

    private func set(for episodeUuid: String, image: UIImage, completion: (() -> Void)?) {
        ImageManager.sharedManager.subscribedPodcastsCache.store(image, forKey: episodeUuid) { _ in
            completion?()
        }
    }
}
