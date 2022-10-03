import Combine
import Foundation

class FilterEpisodeListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var episodes: [EpisodeRowViewModel]
    private var playSource = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()
    let filter: Filter

    convenience init?(filterUUID: String) {
        guard let filter = PlaySourceHelper.playSourceViewModel.fetchFilter(filterUUID) else { return nil }
        self.init(filter: filter)
    }

    init(filter: Filter) {
        self.filter = filter
        episodes = []

        Publishers.Notification.dataUpdated
            .sink { [unowned self] _ in
                self.loadFilterEpisodes()
            }
            .store(in: &cancellables)
    }

    func loadFilterEpisodes() {
        isLoading = episodes.isEmpty
        playSource.fetchFilterEpisodes(filter)
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
