import SwiftUI
import Combine
import PocketCastsDataModel

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
    private var cancellables: Set<AnyCancellable> = []

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
        observeHistoryChanges()
    }

    func load() {
        fetchLocalData()
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
