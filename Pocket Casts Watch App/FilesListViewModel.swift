import Combine
import Foundation
import PocketCastsDataModel

class FilesListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var episodes: [EpisodeRowViewModel]
    @Published var sortOrder: UploadedSort {
        willSet {
            playSource.userEpisodeSortOrder = newValue
        }
    }

    private var playSource = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()

    var supportsSort: Bool {
        playSource.supportsFileSort
    }

    init() {
        episodes = []
        sortOrder = playSource.userEpisodeSortOrder

        Publishers.Merge3(
            Publishers.Notification.userEpisodeDeleted,
            Publishers.Notification.userEpisodesRefreshed,
            Publishers.Notification.dataUpdated
        )
        .sink { [unowned self] _ in
            self.loadUserEpisodes()
        }
        .store(in: &cancellables)

        $sortOrder
            .sink { [unowned self] sortOrder in
                self.loadUserEpisodes(forOrder: sortOrder)
            }
            .store(in: &cancellables)
    }

    func loadUserEpisodes(forOrder: UploadedSort? = nil) {
        isLoading = episodes.isEmpty
        playSource.fetchUserEpisodes(forOrder: forOrder)
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
