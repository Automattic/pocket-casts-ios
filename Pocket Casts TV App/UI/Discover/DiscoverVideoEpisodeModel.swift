import UIKit
import AVFoundation
import PocketCastsServer
import PocketCastsUtils

@Observable
class DiscoverVideoEpisodeModel {

    private let discoverManager: DiscoverManager

    let episode: DiscoverEpisode

    var thumbnail: UIImage?

    init(episode: DiscoverEpisode, discoverManager: DiscoverManager = DiscoverManager.shared) {
        self.episode = episode
        self.discoverManager = discoverManager
    }

    func load() async {
        if let urlString = episode.url, let videoUrl = URL(string: urlString) {
            do {
                var videoFrame: UIImage?
                let cachedVideoFrame = await ImageManager.sharedManager.retrieveDiscoverVideoThumbnail(imageUrl: urlString)
                if cachedVideoFrame != nil {
                    videoFrame = cachedVideoFrame
                } else {
                    let image = try await thumbnail(url: videoUrl, at: CMTime(seconds: 1, preferredTimescale: 600))
                    let _ = await ImageManager.sharedManager.storeDiscoverVideoThumbnail(for: urlString, image: image)
                    videoFrame = image
                }
                await MainActor.run { [videoFrame] in
                    thumbnail = videoFrame
                }
            } catch {
                FileLog.shared.addMessage("[DiscoverVideoEpisodeModel] Failed to generate discover video thumbnail for episode \(episode.uuid ?? "unknown"): \(error.localizedDescription)")
            }
        }
    }

    private func thumbnail(url: URL, at time: CMTime = .zero) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter  = CMTime(seconds: 1, preferredTimescale: 600)

        let (image, _) = try await generator.image(at: time)
        return UIImage(cgImage: image)
    }

    var podcast: DiscoverPodcast? {
        episode.discoverPodcast
    }
}

extension DiscoverEpisode {

    var discoverPodcast: DiscoverPodcast? {
        guard let podcastUuid = self.podcastUuid else {
            return nil
        }
        var podcast = DiscoverPodcast()
        podcast.uuid = podcastUuid
        podcast.title = self.podcastTitle
        return podcast
    }
}
