import Combine
import Foundation

class FilterEpisodeListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var episodes: [EpisodeRowViewModel]
    private var playSource = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()
    let filter: PlaylistRepresentable

    convenience init?(filterUUID: String) {
        guard let filter = PlaySourceHelper.playSourceViewModel.fetchPlaylist(filterUUID) else { return nil }
        self.init(filter: filter)
    }

    init(filter: PlaylistRepresentable) {
        self.filter = filter
        episodes = []

        Publishers.Notification.dataUpdated
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.loadFilterEpisodes()
            }
            .store(in: &cancellables)
    }

    func loadFilterEpisodes() {
        isLoading = episodes.isEmpty
        playSource.fetchPlaylistEpisodes(filter)
            .replaceError(with: [])
            .map {
                $0.map { EpisodeRowViewModel(episode: $0) }
            }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] episodes in
                self.isLoading = false
                self.episodes = episodes
            })
            .store(in: &cancellables)
    }
}
