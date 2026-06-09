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
        case error
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
            // Logged-out users only ever have local history, so there's nothing
            // that can "fail" — treat it as a successful (if empty) load.
            fetchLocalData(syncSucceeded: true)
        }
    }

    func retry() {
        state = .loading
        load()
    }

    private func refreshFromServer() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.apiHandler.retrieveHistory()
                self.fetchLocalData(syncSucceeded: true)
            } catch {
                self.fetchLocalData(syncSucceeded: false, error: error)
            }
        }
    }

    /// Re-reads history from the database and resolves the display state. We
    /// prefer showing whatever is stored locally; the error state is only used
    /// when a server sync failed *and* there's nothing to fall back to.
    private func fetchLocalData(syncSucceeded: Bool, error: Error? = nil) {
        Task {
            let fetched = fetchHistoryEpisodes()
            let episodes = fetched.map { episode in
                EpisodeRowViewModel(episode: episode, podcast: episode.parentPodcast(dataManager: dataManager))
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.episodes = episodes
                if !episodes.isEmpty {
                    self.state = .ready
                    // We already have history to show, so surface a sync failure
                    // unobtrusively with a toast rather than replacing the list.
                    if !syncSucceeded {
                        ToastManager.shared.show(error?.localizedMessage ?? L10n.refreshFailed)
                    }
                } else {
                    // Nothing to fall back to: show the full error state with a retry.
                    self.state = syncSucceeded ? .empty : .error
                }
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
                // A local change (play / remove / sync update) is never a failure,
                // so don't let it flip a populated list into the error state.
                self?.fetchLocalData(syncSucceeded: true)
            }
            .store(in: &cancellables)
    }
}
