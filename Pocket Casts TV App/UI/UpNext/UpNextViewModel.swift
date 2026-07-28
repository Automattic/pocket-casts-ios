import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@Observable
class UpNextViewModel {
    private var cancellables: Set<AnyCancellable> = []
    private let dataManager: DataManager
    private let refreshManager: RefreshManager

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading
    var episodes: [EpisodeRowViewModel] = []

    init(dataManager: DataManager = DataManager.sharedManager, refreshManager: RefreshManager = RefreshManager.shared) {
        self.dataManager = dataManager
        self.refreshManager = refreshManager
        observeUpNextChanges()
    }

    func load() {
        refreshServerData()
        fetchLocalData()
    }

    private func refreshServerData() {
        Task {
            SyncManager.syncReason = nil
            refreshManager.syncUpNext()
        }
    }

    private func fetchLocalData() {
        Task.detached { [dataManager] in
            let episodes = self.loadEpisodeViewModels(using: dataManager)
            await MainActor.run { [weak self] in
                guard let self else { return }
                state = episodes.isEmpty ? .empty : .ready
                self.episodes = episodes
            }
        }
    }

    private func loadEpisodeViewModels(using dataManager: DataManager) -> [EpisodeRowViewModel] {
        dataManager.allUpNextEpisodes().dropFirst().map { episode in
            let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
            return EpisodeRowViewModel(episode: episode, podcast: podcast, source: .upNext)
        }
    }

    fileprivate func observeUpNextChanges() {
        let notificationsToObserve: [Notification.Name] = [
            Constants.Notifications.upNextQueueChanged,
            Constants.Notifications.upNextEpisodeRemoved,
            Constants.Notifications.upNextEpisodeAdded,
        ]

        let publishers = notificationsToObserve.map {
            NotificationCenter.default.publisher(for: $0).map { _ in () }.eraseToAnyPublisher()
        }

        Publishers.MergeMany(publishers)
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
