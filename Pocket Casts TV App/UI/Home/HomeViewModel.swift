import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@Observable
class HomeViewModel {

    private var cancellables: Set<AnyCancellable> = []
    private let dataManager: DataManager

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
        observeDataChanges()
    }

    enum State: Equatable, Hashable {
        case loading
        case ready
    }

    var state: State = .loading

    var currentPlaying: EpisodeRowViewModel?
    var upNext: [EpisodeRowViewModel] = []
    var newReleases: [EpisodeRowViewModel] = []
    var newVideoReleases: [EpisodeRowViewModel] = []

    /// True until playback first starts this session. Used to show the
    /// "Keep Listening" row on Home only before the user has played anything.
    var playbackNotYetStarted = true

    func load() {
        Task {
            let upNextEpisodes = dataManager.allUpNextEpisodes()
            let currentlyPlaying = upNextEpisodes.first.map { withPodcast($0) }
            let upNextEntries = Array(upNextEpisodes.dropFirst().prefix(12)).map { withPodcast($0) }
            let newEpisodes = dataManager.findNewReleaseEpisodes(limit: 12).map { withPodcast($0) }
            let newVideoReleases = dataManager.findNewVideoReleaseEpisodes(limit: 12).map { withPodcast($0) }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.upNext = upNextEntries.map { self.makeRowViewModel(for: $0) }
                if let currentlyPlaying {
                    self.currentPlaying = self.makeRowViewModel(for: currentlyPlaying)
                }
                self.newReleases = newEpisodes.map { self.makeRowViewModel(for: $0) }
                self.newVideoReleases = newVideoReleases.map { self.makeRowViewModel(for: $0) }

                self.state = .ready
            }
        }
    }

    func refresh() {
        RefreshManager.shared.refreshPodcasts()
    }

    private func withPodcast(_ episode: BaseEpisode) -> (episode: BaseEpisode, podcast: Podcast?) {
        (episode, (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) })
    }

    @MainActor
    private func makeRowViewModel(for entry: (episode: BaseEpisode, podcast: Podcast?)) -> EpisodeRowViewModel {
        EpisodeRowViewModel(episode: entry.episode, podcast: entry.podcast, source: .home)
    }

    private func observeDataChanges() {
        let notificationsToObserve: [Notification.Name] = [
            Constants.Notifications.podcastUpdated,
            Constants.Notifications.podcastAdded,
            Constants.Notifications.podcastDeleted,
            Constants.Notifications.upNextQueueChanged,
            Constants.Notifications.upNextEpisodeRemoved,
            Constants.Notifications.upNextEpisodeAdded,
            Constants.Notifications.manyEpisodesChanged,
            ServerNotifications.podcastsRefreshed,
            ServerNotifications.syncCompleted,
            Constants.Notifications.playbackTrackChanged
        ]

        let publishers = notificationsToObserve.map {
            NotificationCenter.default.publisher(for: $0).map { _ in () }.eraseToAnyPublisher()
        }

        Publishers.MergeMany(publishers)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.load()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Constants.Notifications.playbackStarted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.playbackNotYetStarted = false
            }
            .store(in: &cancellables)
    }

    var shouldShowNowPlayingRow: Bool {
        return playbackNotYetStarted && currentPlaying != nil
    }
}
