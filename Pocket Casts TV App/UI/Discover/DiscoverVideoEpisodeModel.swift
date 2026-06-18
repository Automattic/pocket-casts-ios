import UIKit
import AVFoundation
import PocketCastsServer
import PocketCastsUtils

@Observable
class DiscoverVideoEpisodeModel {

    private let discoverManager: DiscoverManager

    private let playbackManager: PlaybackManager

    let episode: DiscoverEpisode

    let maxPreviewTime: Double

    let fadeDuration: TimeInterval

    var thumbnail: UIImage?

    var player: AVPlayer?

    var isPlaying: Bool = false

    private var timeObserver: Any?

    private var fadeTimer: Timer?

    init(episode: DiscoverEpisode, maxPreviewTime: Double = 30, fadeDuration: TimeInterval = 0.5,
         discoverManager: DiscoverManager = DiscoverManager.shared,
         playbackManager: PlaybackManager = .shared) {
        self.episode = episode
        self.maxPreviewTime = maxPreviewTime
        self.fadeDuration = fadeDuration
        self.discoverManager = discoverManager
        self.playbackManager = playbackManager
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        fadeTimer?.invalidate()
    }

    func load() async {
        guard let urlString = episode.url, let videoUrl = URL(string: urlString) else {
            return
        }

        setupPlayer()

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

    private var isFadePausing = false

    private func setupPlayer() {
        guard let urlString = episode.url, let videoUrl = URL(string: urlString) else {
            return
        }
        player = AVPlayer(url: videoUrl)

        let interval = CMTime(seconds: 0.01, preferredTimescale: 600)

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else {
                return
            }
            if time.seconds >= self.maxPreviewTime, !isFadePausing {
                self.pause()
            }
        }
    }

    func play() {
        // Cancel any in-flight fade so it can't pause this fresh playback.
        fadeTimer?.invalidate()
        fadeTimer = nil
        isFadePausing = false

        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        player?.play()
        player?.volume = playbackManager.playing() ? 0 : 1
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = true
        }
    }

    func pause() {
        fadePause(duration: fadeDuration)
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
        }
    }

    func fadePause(duration: TimeInterval) {
        guard let player else {
            isFadePausing = false
            return
        }
        isFadePausing = true

        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)

        var currentStep = 0
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            player.volume -= volumeStep

            if currentStep >= steps {
                timer.invalidate()
                self?.fadeTimer = nil
                player.pause()
                self?.isFadePausing = false
                player.volume = 1.0
            }
        }
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
