import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class PlaylistRefreshOperation: Operation, @unchecked Sendable {
    private let episodesDataManager: EpisodesDataManager
    private let playlist: EpisodeFilter
    private let completion: ([ListEpisode]) -> Void
    private let shouldShowArchived: Bool

    init(
        episodesDataManager: EpisodesDataManager = .init(),
        playlist: EpisodeFilter,
        shouldShowArchived: Bool = false,
        completion: @escaping (([ListEpisode]) -> Void)
    ) {
        self.episodesDataManager = episodesDataManager
        self.playlist = playlist
        self.shouldShowArchived = shouldShowArchived
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            let newData: [ListEpisode]
            if FeatureFlag.playlistsRebranding.enabled {
                newData = episodesDataManager.playlistEpisodes(for: playlist, shouldShowArchived: shouldShowArchived)
            } else {
                newData = episodesDataManager.episodes(for: playlist)
            }

            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.completion(newData)
            }
        }
    }
}
