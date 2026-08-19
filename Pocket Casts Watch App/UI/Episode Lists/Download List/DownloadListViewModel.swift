import Combine
import Foundation
import PocketCastsDataModel

@MainActor
class DownloadListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var episodes: [EpisodeRowViewModel] = []
    @Published var downloadedCount: Int = 0
    let playSourceViewModel = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        downloadedCount = playSourceViewModel.downloadedCount

        Publishers.Merge3(
            Publishers.Notification.dataUpdated,
            Publishers.Notification.episodeDownloadStatusChanged,
            Publishers.Notification.episodeDownloaded
        )
        .receive(on: RunLoop.main)
        .sink(receiveValue: { [unowned self] _ in
            self.loadEpisodes()
        })
        .store(in: &cancellables)
    }

    public func loadEpisodes() {
        isLoading = episodes.isEmpty
        playSourceViewModel.fetchDownloadedEpisodes()
            .replaceError(with: [])
            .receive(on: RunLoop.main)
            .map {
                $0.map { EpisodeRowViewModel(episode: $0) }
            }
            .sink(receiveValue: { [unowned self] episodes in
                self.isLoading = false
                self.episodes = episodes
                self.downloadedCount = playSourceViewModel.downloadedCount
            })
            .store(in: &cancellables)
    }
}
