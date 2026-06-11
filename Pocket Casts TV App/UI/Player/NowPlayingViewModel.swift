import Foundation
import AVFoundation
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
    var player: AVPlayer? {
        didSet {
            observePlayerLoading()
        }
    }
    var episode: BaseEpisode?
    var podcast: Podcast?

    /// True while the player is still preparing its item (initial load or
    /// mid-stream buffering). Drives the branded loading UI in
    /// `MediaOverlayView` and lets `NowPlayingView` suppress AVKit's system
    /// spinner by toggling `showsPlaybackControls`.
    var isLoading: Bool = true

    @ObservationIgnored private var timeControlStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var itemStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var currentItemObservation: NSKeyValueObservation?

    init(playbackManager: PlaybackManager = PlaybackManager.shared, imageManager: ImageManager = ImageManager.sharedManager) {
        self.playbackManager = playbackManager
        self.imageManager = imageManager
        observeUpNextChanges()
    }

    deinit {
        timeControlStatusObservation?.invalidate()
        itemStatusObservation?.invalidate()
        currentItemObservation?.invalidate()
    }

    func load() {
        let newEpisode = playbackManager.currentEpisode()
        guard newEpisode?.uuid != episode?.uuid else {
            return
        }
        episode = newEpisode
        podcast = playbackManager.currentPodcast
        player = playbackManager.avPlayer
        loadEpisodeArtwork()
    }

    private func observePlayerLoading() {
        timeControlStatusObservation?.invalidate()
        itemStatusObservation?.invalidate()
        currentItemObservation?.invalidate()

        guard let player else {
            isLoading = true
            return
        }

        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateLoadingState()
            }
        }

        currentItemObservation = player.observe(\.currentItem, options: [.new, .initial]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                self?.observeCurrentItem(player.currentItem)
                self?.updateLoadingState()
            }
        }

        observeCurrentItem(player.currentItem)
    }

    private func observeCurrentItem(_ item: AVPlayerItem?) {
        itemStatusObservation?.invalidate()
        guard let item else { return }
        itemStatusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateLoadingState()
            }
        }
    }

    private func updateLoadingState() {
        guard let player else {
            isLoading = true
            return
        }
        let waiting = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        let itemNotReady = (player.currentItem?.status ?? .unknown) != .readyToPlay
        isLoading = waiting || itemNotReady
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
}
