import Foundation
import PocketCastsDataModel
import PocketCastsUtils

class PlaylistRefreshOperation: Operation {
    private let episodesDataManager: EpisodesDataManager
    private let playlist: EpisodeFilter
    private let completion: ([ListEpisode]) -> Void

    init(
        episodesDataManager: EpisodesDataManager = .init(),
        playlist: EpisodeFilter,
        completion: @escaping (([ListEpisode]) -> Void)
    ) {
        self.episodesDataManager = episodesDataManager
        self.playlist = playlist
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            let newData: [ListEpisode]
            if FeatureFlag.playlistsRebranding.enabled {
                newData = episodesDataManager.playlistEpisodes(for: playlist)
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
