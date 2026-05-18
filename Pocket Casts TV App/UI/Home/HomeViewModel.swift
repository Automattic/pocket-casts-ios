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
        case empty
    }

    var state: State = .loading

    var podcasts: [Podcast] = []
    var currentPlaying: EpisodeRowViewModel?
    var upNext: [EpisodeRowViewModel] = []
    var recentlyPlayed: [Podcast] = []
    var newReleases: [EpisodeRowViewModel] = []

    func load() {
        Task {
            let podcasts = fetchPodcasts()
            let upNextEpisodes = dataManager.allUpNextEpisodes()
            var newEpisodes = [EpisodeRowViewModel]()
            for podcast in podcasts.prefix(8) {
                guard let latest: Episode = dataManager.findLatestEpisode(podcast: podcast) else {
                    continue
                }
                let result = EpisodeRowViewModel(episode: latest, podcast: podcast)
                newEpisodes.append(result)
            }

            await MainActor.run { [weak self] in
                guard let self else { return }
                recentlyPlayed = Array(podcasts.shuffled().prefix(10))
                self.podcasts = podcasts
                upNext = Array(upNextEpisodes.prefix(3)).map { episode in
                    self.makeRowViewModel(for: episode)
                }
                currentPlaying = upNext.first
                newReleases = newEpisodes
                state = .ready
            }
        }
    }

    private func fetchPodcasts() -> [Podcast] {
        return Array(dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: false).prefix(20))
    }

    private func makeRowViewModel(for episode: BaseEpisode) -> EpisodeRowViewModel {
        let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
        return EpisodeRowViewModel(episode: episode, podcast: podcast)
    }

    private func observeDataChanges() {
        let notificationsToObserve: [Notification.Name] = [
            Constants.Notifications.podcastUpdated,
            Constants.Notifications.podcastAdded,
            Constants.Notifications.podcastDeleted,
            Constants.Notifications.upNextQueueChanged,
            Constants.Notifications.manyEpisodesChanged,
            ServerNotifications.podcastsRefreshed,
            ServerNotifications.syncCompleted
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
    }
}
