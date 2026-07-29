import Foundation
import PocketCastsDataModel
import PocketCastsServer
import Combine

@Observable
class NowPlayingViewModel: Identifiable {

    private var cancellables: Set<AnyCancellable> = []

    private let playbackManager: PlaybackManager
    private let imageManager: ImageManager

    var displayImage: UIImage?
    var imageData: Data?
    var player: AVPlayer?
    var episode: BaseEpisode?
    var podcast: Podcast?
    var isPlaying: Bool = false

    init(playbackManager: PlaybackManager = PlaybackManager.shared, imageManager: ImageManager = ImageManager.sharedManager) {
        self.playbackManager = playbackManager
        self.imageManager = imageManager
        observeUpNextChanges()
        observePlaybackState()
    }

    func load() {
        let newEpisode = playbackManager.currentEpisode()
        guard newEpisode?.uuid != episode?.uuid else {
            return
        }
        episode = newEpisode
        podcast = playbackManager.currentPodcast
        player = playbackManager.avPlayer
        isPlaying = playbackManager.playing()
        loadEpisodeArtwork()
    }

    func loadEpisodeArtwork() {
        Task.detached { [weak self] in
            let image = await self?.loadEpisodeArtworkData()
            let data = image?.jpegData(compressionQuality: 0.9)
            await MainActor.run { [weak self] in
                self?.imageData = data
                self?.displayImage = image
                self?.player = self?.playbackManager.avPlayer
            }
        }
    }

    var isVideo: Bool {
        return episode?.videoPodcast() ?? false
    }

    var displayTitle: String {
        return episode?.displayableTitle() ?? ""
    }

    var displaySubTitle: String {
        return podcast?.title ?? ""
    }

    var displayInfo: String {
        return episode?.displayableInfo() ?? ""
    }

    var displayDate: String {
        return episode?.shortPublishedDate() ?? ""
    }

    var displayDuration: String {
        return episode?.displayableDuration ?? ""
    }

    var displayImageData: Data? {
        return imageData
    }

    var playbackSpeed: Double {
        get {
            playbackManager.effects().playbackSpeed
        }
        set {
            playbackManager.effects().playbackSpeed = newValue
            playbackManager.applyCurrentEffect()
        }
    }

    var volumeBoost: Bool {
        get {
            playbackManager.effects().volumeBoost
        }
        set {
            playbackManager.effects().volumeBoost = newValue
            playbackManager.applyCurrentEffect()
        }
    }

    var trimSilence: TrimSilenceAmount {
        get {
            playbackManager.effects().trimSilence
        }
        set {
            playbackManager.effects().trimSilence = newValue
            playbackManager.applyCurrentEffect()
        }
    }

    private func loadEpisodeArtworkData() async -> UIImage? {
        guard let episode else {
            return nil
        }

        return await imageManager.imageForEpisode(episode, size: .page)
    }

    var podcastUuid: String? {
        if let episode = episode as? Episode {
            return episode.podcastUuid
        } else {
            return nil
        }
    }

    fileprivate func observeUpNextChanges() {
        NotificationCenter.default.publisher(for: Constants.Notifications.playbackTrackChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                load()
            }
            .store(in: &cancellables)
    }

    private func observePlaybackState() {
        // Observe the AVPlayer's timeControlStatus directly so we catch
        // pauses triggered by the AVPlayerViewController transport bar.
        playbackManager.avPlayer?.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isPlaying = (status == .playing)
            }
            .store(in: &cancellables)
    }
}
