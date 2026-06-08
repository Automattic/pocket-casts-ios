import SwiftUI
import Combine
import PocketCastsDataModel
import PocketCastsServer

@MainActor @Observable
class ListeningHistoryViewModel {

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
        observeHistoryChanges()
    }

    func load() {
        if SyncManager.isUserLoggedIn() {
            refreshFromServer()
        } else {
            fetchLocalData()
        }
    }

    /// Pulls the latest history from the server. `SyncHistoryTask` writes the
    /// returned changes into the local database before completing, so once it
    /// finishes we simply re-read from the database to get a consistent,
    /// locally-backed list. On failure we fall back to whatever is already
    /// stored locally.
    private func refreshFromServer() {
        apiHandler.retrieveHistory { [weak self] in
            self?.fetchLocalData()
        }
    }

    private func fetchLocalData() {
        Task {
            let fetched = fetchHistoryEpisodes()
            let episodes = fetched.map { episode in
                EpisodeRowViewModel(episode: episode, podcast: episode.parentPodcast(dataManager: dataManager))
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.episodes = episodes
                self.state = episodes.isEmpty ? .empty : .ready
            }
        }
    }

    private func fetchHistoryEpisodes() -> [Episode] {
        dataManager.findEpisodesWhere(customWhere: "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000", arguments: nil)
    }

    private func observeHistoryChanges() {
        // History changes when episodes are played (which updates their interaction
        // date and reorders the list), when entries are removed, or when a sync
        // brings in playback from another device.
        let names: [Notification.Name] = [
            Constants.Notifications.listeningHistoryChanged,
            Constants.Notifications.playbackTrackChanged,
            Constants.Notifications.playbackEnded
        ]
        Publishers.MergeMany(names.map { NotificationCenter.default.publisher(for: $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchLocalData()
            }
            .store(in: &cancellables)
    }
}
