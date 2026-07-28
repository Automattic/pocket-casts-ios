import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@MainActor @Observable
class StarredEpisodesViewModel {

    enum State: Equatable {
        case loading
        case ready
        case empty
    }

    private(set) var state: State = .loading
    private(set) var episodes: [EpisodeRowViewModel] = []

    private let dataManager: DataManager
    private let apiHandler: ApiServerHandler
    private var cancellables: Set<AnyCancellable> = []

    init(dataManager: DataManager = DataManager.sharedManager, apiHandler: ApiServerHandler = .shared) {
        self.dataManager = dataManager
        self.apiHandler = apiHandler
        observeStarredChanges()
    }

    func load() {
        if SyncManager.isUserLoggedIn() {
            refreshFromServer()
        } else {
            fetchLocalData()
        }
    }

    /// Pulls the latest starred list from the server. `RetrieveStarredTask`
    /// stars the returned episodes locally before completing, so once it
    /// finishes we simply re-read from the database to get a consistent,
    /// locally-backed list. On failure (`nil`) we fall back to whatever is
    /// already stored locally.
    private func refreshFromServer() {
        apiHandler.retrieveStarred { [weak self] _ in
            self?.fetchLocalData()
        }
    }

    private func fetchLocalData() {
        Task.detached { [dataManager] in
            let episodes = self.loadEpisodeViewModels(using: dataManager)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.episodes = episodes
                self.state = episodes.isEmpty ? .empty : .ready
            }
        }
    }

    nonisolated private func loadEpisodeViewModels(using dataManager: DataManager) -> [EpisodeRowViewModel] {
        dataManager.fetchStarredEpisodes().map { episode in
            EpisodeRowViewModel(episode: episode, podcast: episode.parentPodcast(dataManager: dataManager), source: .starred)
        }
    }

    private func observeStarredChanges() {
        NotificationCenter.default.publisher(for: Constants.Notifications.episodeStarredChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchLocalData()
            }
            .store(in: &cancellables)
    }
}

private extension DataManager {
    func fetchStarredEpisodes() -> [Episode] {
        findEpisodesWhere(customWhere: "keepEpisode = 1 ORDER BY starredModified DESC LIMIT 1000", arguments: nil)
    }
}
