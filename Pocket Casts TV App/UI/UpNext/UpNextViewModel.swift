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
        Task {
            let fetched = fetchUpNextEpisodes()
            let episodes = fetched.map { episode in
                let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
                return EpisodeRowViewModel(episode: episode, podcast: podcast)
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                state = episodes.isEmpty ? .empty : .ready
                self.episodes = episodes
            }
        }
    }

    private func fetchUpNextEpisodes() -> [BaseEpisode] {
        dataManager.allUpNextEpisodes()
    }

    fileprivate func observeUpNextChanges() {
        NotificationCenter.default.publisher(for: Constants.Notifications.upNextQueueChanged)
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
