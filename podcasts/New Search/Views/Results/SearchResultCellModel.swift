import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils
import Combine

class SearchResultCellModel: ObservableObject, MainEpisodeActionViewDelegate {

    var episode: EpisodeSearchResult?
    var podcastFolder: PodcastFolderSearchResult?
    private(set) var realEpisode: BaseEpisode?

    @Published var refreshTrigger: Bool = true

    init(episode: EpisodeSearchResult?, podcastFolder: PodcastFolderSearchResult?) {
        self.episode = episode
        self.podcastFolder = podcastFolder
        setupObservers()
    }

    func playTapped() {
        guard let episode else {
            return
        }
        PlaybackManager.shared.playEpisodeSearchResult(episode)
    }

    func pauseTapped() {
        PlaybackActionHelper.pause()
    }

    func downloadTapped() {}

    func stopDownloadTapped() {}

    func errorTapped() {}

    func waitingForWifiTapped() {}

    private var cancellables = Set<AnyCancellable>()

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
                guard let episodeUUID = notification.object as? String ?? PlaybackManager.shared.currentEpisode()?.uuid,
                      episodeUUID == episode.uuid
                else {
                    return
                }
                let realEpisode = DataManager.sharedManager.findBaseEpisode(uuid: episodeUUID)
                self.realEpisode = realEpisode
                self.refreshTrigger.toggle()
            })
            .store(in: &cancellables)
    }
}
