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
        Task.detached { [dataManager] in
            let episodes = self.loadEpisodes(using: dataManager)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.episodes = episodes.map { EpisodeRowViewModel(episode: $0.episode, podcast: $0.podcast, source: .listeningHistory) }
                self.state = episodes.isEmpty ? .empty : .ready
            }
        }
    }

    nonisolated private func loadEpisodes(using dataManager: DataManager) -> [(episode: Episode, podcast: Podcast?)] {
        dataManager.fetchHistoryEpisodes().map { episode in
            (episode, episode.parentPodcast(dataManager: dataManager))
        }
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

private extension DataManager {
     func fetchHistoryEpisodes() -> [Episode] {
        findEpisodesWhere(customWhere: "lastPlaybackInteractionDate IS NOT NULL AND lastPlaybackInteractionDate > 0 ORDER BY lastPlaybackInteractionDate DESC LIMIT 1000", arguments: nil)
    }
}
