import Foundation
import PocketCastsDataModel

class PlaylistDetailFetchOperation: Operation {
    typealias CompletionHandler = ([ListEpisode], Int) -> Void

    private let episodesDataManager: EpisodesDataManager
    private let dataManager: DataManager
    private let playlist: EpisodeFilter
    private let completion: CompletionHandler
    private let shouldShowArchived: Bool

    init(
        dataManager: DataManager = .sharedManager,
        episodesDataManager: EpisodesDataManager = .init(),
        playlist: EpisodeFilter,
        shouldShowArchived: Bool = false,
        completion: @escaping CompletionHandler
    ) {
        self.dataManager = dataManager
        self.episodesDataManager = episodesDataManager
        self.playlist = playlist
        self.shouldShowArchived = shouldShowArchived
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            let newData = episodesDataManager.playlistEpisodes(for: playlist, shouldShowArchived: shouldShowArchived)

            let archivedEpisodesCount = dataManager.playlistArchivedEpisodeCount(
                for: playlist,
                episodeUuidToAdd: playlist.episodeUuidToAddToQueries()
            )

            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.completion(newData, archivedEpisodesCount)
            }
        }
    }
}
