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

    let playDelay: TimeInterval

    var thumbnail: UIImage?

    var player: AVPlayer?

    var isPlaying: Bool = false

    private var timeObserver: Any?

    private var fadeTimer: Timer?

    private var playDelayTimer: Timer?

    init(episode: DiscoverEpisode, maxPreviewTime: Double = 30, fadeDuration: TimeInterval = 0.5,
         playDelay: TimeInterval = 2,
         discoverManager: DiscoverManager = DiscoverManager.shared,
         playbackManager: PlaybackManager = .shared) {
        self.episode = episode
        self.maxPreviewTime = maxPreviewTime
        self.fadeDuration = fadeDuration
        self.playDelay = playDelay
        self.discoverManager = discoverManager
        self.playbackManager = playbackManager
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        fadeTimer?.invalidate()
        playDelayTimer?.invalidate()
    }

    func load() async {
        guard let urlString = episode.videoURL, let videoUrl = URL(string: urlString) else {
            FileLog.shared.addMessage("[DiscoverVideoEpisodeModel] Failed to get a video url for episode \(episode.uuid ?? "unknown")")
            return
        }

        setupPlayer(for: videoUrl)

        do {
            let videoFrame: UIImage
            if let cachedVideoFrame = await ImageManager.sharedManager.retrieveDiscoverVideoThumbnail(imageUrl: urlString) {
                videoFrame = cachedVideoFrame
            } else {
                let image: UIImage
                if FeatureFlag.captureBestFrame.enabled {
                    image = try await thumbnailFromBestFrame(url: videoUrl)
                } else {
                    image = try await thumbnail(url: videoUrl, at: CMTime(seconds: 1, preferredTimescale: 600))
                }
                _ = await ImageManager.sharedManager.storeDiscoverVideoThumbnail(for: urlString, image: image)
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

    private func thumbnailFromBestFrame(url: URL) async throws -> UIImage {
        try await BestFrameSelector.bestFrame(from: AVURLAsset(url: url), endPercentage: 0.1)
    }

    var podcast: DiscoverPodcast? {
        episode.discoverPodcast
    }

    private var isFadePausing: Bool { fadeTimer != nil }

    private func setupPlayer(for videoUrl: URL) {
        player = AVPlayer(url: videoUrl)

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else {
                return
            }
            if time.seconds >= self.maxPreviewTime, self.isPlaying, !isFadePausing {
                self.pause()
            }
        }
    }

    func play() {
        // Wait a moment before starting so scrolling past a card doesn't trigger playback.
        playDelayTimer?.invalidate()
        playDelayTimer = Timer.scheduledTimer(withTimeInterval: playDelay, repeats: false) { [weak self] _ in
            self?.playDelayTimer = nil
            self?.startPlayback()
        }
    }

    private func startPlayback() {
        // Cancel any in-flight fade so it can't pause this fresh playback.
        fadeTimer?.invalidate()
        fadeTimer = nil

        guard let player else {
            isPlaying = false
            return
        }

        player.volume = playbackManager.isPlaying ? 0 : 0.5
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        player.play()
        isPlaying = true
    }

    func pause() {
        // Cancel a pending delayed play so an unfocused card never starts.
        playDelayTimer?.invalidate()
        playDelayTimer = nil

        fadePause(duration: fadeDuration)
        isPlaying = false
    }

    func fadePause(duration: TimeInterval) {
        guard let player else {
            return
        }

        // Nothing to fade when already muted (something else is playing) — just stop.
        guard player.volume > 0 else {
            player.pause()
            return
        }

        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = player.volume / Float(steps)

        var currentStep = 0
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            player.volume = max(0, player.volume - volumeStep)

            if currentStep >= steps {
                timer.invalidate()
                self?.fadeTimer = nil
                player.pause()
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
