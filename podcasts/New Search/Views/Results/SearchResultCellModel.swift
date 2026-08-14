import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils
import Combine

private enum EpisodeLookupError: Error {
    case episodeNotFound
}

@MainActor
class SearchResultCellModel: ObservableObject, MainEpisodeActionViewDelegate {

    var episode: EpisodeSearchResult?
    var podcastFolder: PodcastFolderSearchResult?
    private(set) var realEpisode: BaseEpisode?

    @Published var refreshTrigger: Bool = true

    /// True while the episode is being fetched from the server before playback can start.
    @Published private(set) var isLoadingEpisode = false

    /// Delayed so the spinner doesn't flash when the episode loads quickly.
    @Published private(set) var showsLoadingSpinner = false

    private static let loadingSpinnerDelay: TimeInterval = 0.5

    private var cancellables = Set<AnyCancellable>()

    init(episode: EpisodeSearchResult?, podcastFolder: PodcastFolderSearchResult?) {
        self.episode = episode
        self.podcastFolder = podcastFolder
        reloadRealEpisode()
        setupObservers()
    }

    func playTapped() {
        guard let episode, !isLoadingEpisode else {
            return
        }
        isLoadingEpisode = true
        Task { @MainActor in
            let spinnerTask = Task { @MainActor in
                try await Task.sleep(nanoseconds: UInt64(Self.loadingSpinnerDelay * TimeInterval(NSEC_PER_SEC)))
                try Task.checkCancellation()
                showsLoadingSpinner = true
            }
            defer {
                spinnerTask.cancel()
                isLoadingEpisode = false
                showsLoadingSpinner = false
            }
            do {
                try await PlaybackManager.shared.playEpisodeSearchResult(episode)
            } catch {
                HapticsHelper.triggerErrorHaptic()
                Toast.show(L10n.discoverEpisodeFailToLoad)
            }
        }
    }

    func pauseTapped() {
        PlaybackActionHelper.pause()
    }

    func downloadTapped() {
        guard let episode, !isLoadingEpisode else { return }

        // A search result's episode isn't necessarily in the database yet (the user might
        // not be subscribed to the podcast), so make sure it exists before queuing it for
        // download — mirroring `playEpisodeSearchResult`.
        if DataManager.sharedManager.findBaseEpisode(uuid: episode.uuid) != nil {
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
            return
        }

        isLoadingEpisode = true
        Task { @MainActor in
            let spinnerTask = Task { @MainActor in
                try await Task.sleep(nanoseconds: UInt64(Self.loadingSpinnerDelay * TimeInterval(NSEC_PER_SEC)))
                try Task.checkCancellation()
                showsLoadingSpinner = true
            }
            defer {
                spinnerTask.cancel()
                isLoadingEpisode = false
                showsLoadingSpinner = false
            }
            do {
                guard try await ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: episode.uuid, podcastUuid: episode.podcastUuid) != nil else {
                    throw EpisodeLookupError.episodeNotFound
                }
                PlaybackActionHelper.download(episodeUuid: episode.uuid)
                reloadRealEpisode()
                refreshTrigger.toggle()
            } catch {
                HapticsHelper.triggerErrorHaptic()
                Toast.show(L10n.discoverEpisodeFailToLoad)
            }
        }
    }

    func stopDownloadTapped() {
        guard let episode else { return }
        PlaybackActionHelper.stopDownload(episodeUuid: episode.uuid)
    }

    func errorTapped() {
        guard let episode else { return }
        if realEpisode?.playbackError() == true {
            playTapped()
        } else {
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
        }
    }

    func waitingForWifiTapped() {
        guard let episode else { return }
        PlaybackActionHelper.overrideWaitingForWifi(episodeUuid: episode.uuid, autoDownloadStatus: .autoDownloaded)
    }

    private func reloadRealEpisode() {
        guard let episode else { return }
        realEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episode.uuid)
    }

    private func setupObservers() {
        guard let episode else {
            //Only need to setup Observers for podcast episodes
            return
        }

        Publishers.Merge3(
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackEnded),
            NotificationCenter.default.publisher(for: Constants.Notifications.playbackPaused),
        )
        .receive(on: OperationQueue.main)
        .sink(receiveValue: { [unowned self] _ in
            self.refreshTrigger.toggle()
        })
        .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.playbackProgress)
            .receive(on: OperationQueue.main)
            .sink(receiveValue: { [unowned self] notification in
                guard let episodeUUID = notification.object as? String ?? PlaybackManager.shared.currentEpisode?.uuid,
                      episodeUUID == episode.uuid
                else {
                    return
                }
                self.realEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUUID)
                self.refreshTrigger.toggle()
            })
            .store(in: &cancellables)

        // Keep the download/play action button in sync while a download is queued, in progress,
        // finishes, or fails — otherwise the button never reflects the tap. Mirrors `EpisodeCell`.
        NotificationCenter.default.publisher(for: Constants.Notifications.downloadProgress)
            .receive(on: OperationQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self,
                      DownloadManager.shared.progressManager.progressForEpisode(episode.uuid) != nil else { return }
                // Only hit the DB when our cached episode doesn't yet reflect the download; live
                // progress is read straight from the DownloadManager when the button repopulates.
                if self.realEpisode?.downloading() != true {
                    self.reloadRealEpisode()
                }
                self.refreshTrigger.toggle()
            })
            .store(in: &cancellables)

        Publishers.Merge(
            NotificationCenter.default.publisher(for: Constants.Notifications.episodeDownloadStatusChanged),
            NotificationCenter.default.publisher(for: Constants.Notifications.episodeDownloaded)
        )
        .receive(on: OperationQueue.main)
        .sink(receiveValue: { [weak self] notification in
            guard let self, notification.object as? String == episode.uuid else { return }
            self.reloadRealEpisode()
            self.refreshTrigger.toggle()
        })
        .store(in: &cancellables)
    }
}
