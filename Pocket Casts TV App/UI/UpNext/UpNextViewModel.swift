import SwiftUI
import Combine
import PocketCastsDataModel

@Observable
class UpNextViewModel {

    private let dataManager: DataManager

    enum State: Equatable, Hashable {
        case loading
        case ready
        case empty
    }

    var state: State = .loading
    var episodes: [EpisodeRowViewModel] = []

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    func load() {
        Task {
            let fetched = fetchUpNextEpisodes()
            episodes = fetched.map { episode in
                let podcast = (episode as? Episode).flatMap { $0.parentPodcast(dataManager: dataManager) }
                return EpisodeRowViewModel(
                    episode: episode,
                    podcastUUID: podcast?.uuid,
                    podcastTitle: podcast?.title,
                    podcastDescription: podcast?.podcastDescription
                )
            }
            state = episodes.isEmpty ? .empty : .ready
        }
    }

    private func fetchUpNextEpisodes() -> [BaseEpisode] {
        dataManager.allUpNextEpisodes()
    }
}
