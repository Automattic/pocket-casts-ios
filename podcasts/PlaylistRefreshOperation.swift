import Foundation
import PocketCastsDataModel

class PlaylistRefreshOperation: Operation {
    private let episodesDataManager: EpisodesDataManager
    private let tableView: UITableView
    private let filter: EpisodeFilter
    private let completion: ([ListEpisode]) -> Void

    init(episodesDataManager: EpisodesDataManager = EpisodesDataManager(), tableView: UITableView, filter: EpisodeFilter, completion: @escaping (([ListEpisode]) -> Void)) {
        self.episodesDataManager = episodesDataManager
        self.tableView = tableView
        self.filter = filter
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            let newData: [ListEpisode] = episodesDataManager.get(.filter(filter))

            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.completion(newData)
            }
        }
    }
}
