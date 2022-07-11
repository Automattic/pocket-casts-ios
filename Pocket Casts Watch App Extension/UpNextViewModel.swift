import Combine
import Foundation
import PocketCastsDataModel

class UpNextViewModel: ObservableObject {
    @Published var isPlaying: Bool
    @Published var isEmpty: Bool = false
    @Published var upNextTitle: String?
    @Published var episodes: [EpisodeRowViewModel]
    private var playSource = PlaySourceHelper.playSourceViewModel
    private var cancellables = Set<AnyCancellable>()

    init() {
        upNextTitle = playSource.nowPlayingEpisode?.subTitle()
        episodes = playSource.episodesInQueue.map { EpisodeRowViewModel(episode: $0) }
        isPlaying = playSource.isPlaying

        Publishers.Notification.playbackChanged
            .map { [unowned self] _ in
                self.playSource.isPlaying
            }
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)

        Publishers.CombineLatest($upNextTitle, $episodes)
            .receive(on: RunLoop.main)
            .map { upNextEpisode, episodes in
                upNextEpisode == nil && episodes.isEmpty
            }
            .assign(to: &$isEmpty)

        Publishers.Merge3(
            Publishers.Notification.dataUpdated,
            Publishers.Notification.upNextEpisodeChanged,
            Publishers.Notification.upNextQueueChanged
        )
        .receive(on: RunLoop.main)
        .sink { [unowned self] _ in
            self.upNextTitle = playSource.nowPlayingEpisode?.subTitle()
            self.episodes = playSource.episodesInQueue.map { EpisodeRowViewModel(episode: $0) }
            self.isPlaying = playSource.isPlaying
        }
        .store(in: &cancellables)
    }

    func clearUpNext() {
        playSource.clearUpNext()
    }
}
