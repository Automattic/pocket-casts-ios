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

    @MainActor
    private var artworkManager = EpisodeArtwork()

    /// True while the player is still preparing its item (initial load or
    /// mid-stream buffering). Drives the branded loading UI in
    /// `MediaOverlayView` and lets `NowPlayingView` suppress AVKit's system
    /// spinner by toggling `showsPlaybackControls`.
    var isLoading: Bool = true
    var isFirstLoad: Bool = false
    var isFailed: Bool = false
    var isPlaying: Bool = false

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
        timeControlStatusObservation = nil
        itemStatusObservation = nil
        currentItemObservation = nil
    }

    private var seekAfterLoad = false

    func load() {
        let newEpisode = playbackManager.currentEpisode
        guard newEpisode?.uuid != episode?.uuid else {
            return
        }
        episode = newEpisode
        isFirstLoad = true
        podcast = playbackManager.currentPodcast
        player = playbackManager.avPlayer
        if !playbackManager.isPlaying, !playbackManager.isReadyToPlay {
            playbackManager.loadCurrentEpisode()
            seekAfterLoad = true
        }
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

        PlayerStatusObserver.shared.observe(player: player)
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
            isFailed = false
            return
        }
        let waiting = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        let status = player.currentItem?.status ?? .unknown
        let itemNotReady = status == .unknown
        isLoading = waiting || itemNotReady
        isFailed = status == .failed
        isPlaying = player.timeControlStatus == .playing
        if !isLoading {
            isFirstLoad = false
        }
        if !isLoading, seekAfterLoad {
            seekAfterLoad = false
            // The delay is needed only for videos episodes.
            // For some reason the AVPlayerViewController does not accept seeks immediately after loading, and resets the position to zero
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(1))) { [weak self] in
                guard let self else { return }
                PlayerStatusObserver.shared.skipNextEvents(2)
                playbackManager.seekToStartingPosition()
            }
        }
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
        guard let episode else {
            return false
        }
        return EpisodeManager.isVideo(episode)
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

        if Settings.loadEmbeddedImages, let podcastEpisode = episode as? Episode,
           let image = await artworkManager.artworkFromShowNotes(podcastUuid: podcastEpisode.podcastUuid, episodeUuid: podcastEpisode.uuid) {
            return image
        }

        return await imageManager.imageForEpisode(episode, size: .page)
    }

    var podcastUuid: String? {
        return podcast?.uuid ?? (episode as? Episode)?.podcastUuid
    }

    var isPlayed: Bool {
        episode?.played() ?? false
    }

    var canArchive: Bool {
        episode is Episode
    }

    var isArchived: Bool {
        (episode as? Episode)?.archived ?? false
    }

    func markAsPlayed() {
        guard let episode else { return }
        EpisodeManager.markAsPlayed(episode: episode, fireNotification: true)
    }

    func markAsUnplayed() {
        guard let episode else { return }
        EpisodeManager.markAsUnplayed(episode: episode, fireNotification: true)
    }

    func archive() {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.archiveEpisode(episode: episode, fireNotification: true)
    }

    func unarchive() {
        guard let episode = episode as? Episode else { return }
        EpisodeManager.unarchiveEpisode(episode: episode, fireNotification: true)
    }

    var errorMessage: String {
        return playbackManager.activeError?.shortUserMessage ?? L10n.playerErrorShortPlaybackError
    }

    var isTrimSilenceAvailable: Bool {
        return playbackManager.silenceRemovalAvailable()
    }

    var isVolumeBoostAvailable: Bool {
        return playbackManager.volumeBoostAvailable()
    }

    var maxPlaybackSpeed: Double {
        var maxSpeed = SharedConstants.PlaybackEffects.maximumPlaybackSpeed
        guard let episode else {
            return maxSpeed
        }
        if EpisodeManager.hasHLSStream(episode) {
            maxSpeed = SharedConstants.PlaybackEffects.maximumHlsPlaybackSpeed
        }
        return maxSpeed
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
