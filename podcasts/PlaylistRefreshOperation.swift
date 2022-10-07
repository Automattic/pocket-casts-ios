import Foundation
import PocketCastsDataModel

class PlaylistRefreshOperation: Operation {
    private let tableView: UITableView
    private let filter: EpisodeFilter
    private let completion: ([ListEpisode]) -> Void

    init(tableView: UITableView, filter: EpisodeFilter, completion: @escaping (([ListEpisode]) -> Void)) {
        self.tableView = tableView
        self.filter = filter
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            let query = PlaylistHelper.queryFor(filter: filter, episodeUuidToAdd: filter.episodeUuidToAddToQueries(), limit: Constants.Limits.maxFilterItems)
            let tintColor = filter.playlistColor()
            let newData = EpisodeTableHelper.loadEpisodes(tintColor: tintColor, query: query, arguments: nil)

            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.completion(newData)
            }
        }
    }
}
