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
        guard let episode else { return }

        withLoadingSpinner {
            try await PlaybackManager.shared.playEpisodeSearchResult(episode)
        }
    }

    func pauseTapped() {
        PlaybackActionHelper.pause()
    }

    func downloadTapped() {
        guard let episode, !isLoadingEpisode else { return }

        if let existingEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episode.uuid) {
            realEpisode = existingEpisode
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
            return
        }

        withLoadingSpinner { [weak self] in
            guard let self else { return }
            let resolvedEpisode = try await self.resolveEpisode(episode)
            PlaybackActionHelper.download(episodeUuid: episode.uuid)
            self.realEpisode = resolvedEpisode
            self.refreshTrigger.toggle()
        }
    }

    func stopDownloadTapped() {
        guard let episode, !isLoadingEpisode else { return }
        PlaybackActionHelper.stopDownload(episodeUuid: episode.uuid)
    }

    func errorTapped() {
        guard let realEpisode else { return }

        let optionsPicker = OptionsPicker(title: nil)
        if realEpisode.playbackError() {
            let retryAction = OptionAction(label: L10n.retry, icon: nil, action: { [weak self] in
                self?.playTapped()
            })
            optionsPicker.addDescriptiveActions(title: L10n.playbackFailed, message: realEpisode.playbackErrorDetails, icon: "option-alert", actions: [retryAction])
        } else {
            let retryAction = OptionAction(label: L10n.retry, icon: nil, action: { [weak self] in
                self?.downloadTapped()
            })
            optionsPicker.addDescriptiveActions(title: L10n.downloadFailed, message: realEpisode.readableErrorMessage(), icon: "option-alert", actions: [retryAction])
        }
        optionsPicker.present()
    }

    func waitingForWifiTapped() {
        guard let episode, !isLoadingEpisode else { return }
        PlaybackActionHelper.overrideWaitingForWifi(episodeUuid: episode.uuid, autoDownloadStatus: .autoDownloaded)
    }

    /// A search result's episode isn't necessarily in the database yet (the user might not be
    /// subscribed to the podcast), so fetch it from the server when it's missing.
    private func resolveEpisode(_ episode: EpisodeSearchResult) async throws -> BaseEpisode {
        if let existingEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episode.uuid) {
            return existingEpisode
        }
        guard let addedEpisode = try await ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: episode.uuid, podcastUuid: episode.podcastUuid) else {
            throw EpisodeLookupError.episodeNotFound
        }
        return addedEpisode
    }

    /// Runs `work`, showing the row's spinner if it doesn't finish quickly and surfacing a toast if it fails.
    private func withLoadingSpinner(_ work: @escaping @MainActor () async throws -> Void) {
        guard !isLoadingEpisode else { return }

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
                try await work()
            } catch is CancellationError {
            } catch {
                HapticsHelper.triggerErrorHaptic()
                Toast.show(L10n.discoverEpisodeFailToLoad)
            }
        }
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
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] _ in
            self?.refreshTrigger.toggle()
        })
        .store(in: &cancellables)

        // `playbackFailed` carries no episode UUID, but it only fires when playback actually fails,
        // so reloading unconditionally is cheap.
        NotificationCenter.default.publisher(for: Constants.Notifications.playbackFailed)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.reloadRealEpisode()
                self?.refreshTrigger.toggle()
            })
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.playbackProgress)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] notification in
                guard let self,
                      let episodeUUID = notification.object as? String ?? PlaybackManager.shared.currentEpisode?.uuid,
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
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] notification in
                guard let self,
                      notification.object as? String == episode.uuid,
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
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] notification in
            guard let self, notification.object as? String == episode.uuid else { return }
            self.reloadRealEpisode()
            self.refreshTrigger.toggle()
        })
        .store(in: &cancellables)
    }
}
