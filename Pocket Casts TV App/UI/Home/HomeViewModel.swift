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
            let newEpisodes = dataManager.findNewReleaseEpisodes(limit: 12).map { episode in
                makeRowViewModel(for: episode)
            }
            let newVideoReleases = dataManager.findNewVideoReleaseEpisodes(limit: 12).map { episode in
                makeRowViewModel(for: episode)
            }
            await MainActor.run { [weak self, newEpisodes] in
                guard let self else { return }
                upNext = Array(upNextEpisodes.dropFirst().prefix(12)).map { episode in
                    self.makeRowViewModel(for: episode)
                }
                if let currentlyPlaying = upNextEpisodes.first {
                    currentPlaying = makeRowViewModel(for: currentlyPlaying)
                }
                newReleases = newEpisodes
                self.newVideoReleases = newVideoReleases

                state = .ready
            }
        }
    }

    func refresh() {
        RefreshManager.shared.refreshPodcasts()
    }

    private func makeRowViewModel(for episode: BaseEpisode) -> EpisodeRowViewModel {
        let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
        return EpisodeRowViewModel(episode: episode, podcast: podcast, source: .home)
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
