import Foundation
import Kingfisher
import PocketCastsServer
import PocketCastsUtils
import AVFoundation

/// Extracts artwork from a streaming episode (if there's any)
class EpisodeArtwork {
    private let imageManager: ImageManager

    /// Track in-progress artwork load tasks by episode UUID to prevent redundant requests and allow cancellation
    private var inProgressArtworkLoads: [String: Task<Void, Never>] = [:]

    init(imageManager: ImageManager = .sharedManager) {
        self.imageManager = imageManager
    }

    /// Attempts to load episode artwork with the following priority (matching Android):
    /// 1. Show notes image URL from the server (publisher intent takes precedence)
    /// 2. Embedded artwork from the AVAsset (ID3 tags)
    /// If an image is retrieved, `episodeEmbeddedArtworkLoaded` notification is triggered
    /// - Parameters:
    ///   - asset: an AVAsset
    ///   - podcastUuid: the UUID of the current playing podcast
    ///   - episodeUuid: the UUID of the current playing episode
    func loadEmbeddedImage(asset: AVAsset?, podcastUuid: String, episodeUuid: String) {
        guard Settings.loadEmbeddedImages,
              !isCached(episodeUuid: episodeUuid),
              inProgressArtworkLoads[episodeUuid] == nil else {
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }

            defer {
                self.inProgressArtworkLoads[episodeUuid] = nil
            }

            // Priority 1: Show notes image URL (publisher intent takes precedence)
            if await self.loadArtworkFromShowNotes(podcastUuid: podcastUuid, episodeUuid: episodeUuid) {
                return
            }

            guard !Task.isCancelled else { return }

            // Priority 2: Embedded artwork from audio file metadata
            if let assetEpisodeArtwork = self.loadEpisodeArtwork(from: asset) {
                self.imageManager.save(assetEpisodeArtwork, for: episodeUuid)
            }
        }

        inProgressArtworkLoads[episodeUuid] = task
    }

    /// Cancel any in-progress artwork load for the given episode
    func cancelArtworkLoad(for episodeUuid: String) {
        inProgressArtworkLoads[episodeUuid]?.cancel()
        inProgressArtworkLoads[episodeUuid] = nil
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

    /// Attempts to load episode artwork from show notes URL.
    /// - Returns: true if artwork was successfully loaded and saved, false otherwise
    private func loadArtworkFromShowNotes(podcastUuid: String, episodeUuid: String) async -> Bool {
        guard let imageUrl = try? await ShowInfoCoordinator.shared.loadEpisodeArtworkUrl(podcastUuid: podcastUuid, episodeUuid: episodeUuid),
              let url = URL(string: imageUrl) else {
            return false
        }

        // Resize image to avoid really big images that appear
        // super blurred on CarPlay.
        // If the image is smaller to the given size, no downsampling is done.
        let size = imageManager.biggestPodcastImageSize
        let resizeProcessor = DownsamplingImageProcessor(size: .init(width: size, height: size))

        return await withCheckedContinuation { continuation in
            KingfisherManager.shared.retrieveImage(with: url, options: [.processor(resizeProcessor)]) { [weak self] result in
                guard !Task.isCancelled else {
                    continuation.resume(returning: false)
                    return
                }
                if let image = try? result.get().image {
                    self?.imageManager.save(image, for: episodeUuid)
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
