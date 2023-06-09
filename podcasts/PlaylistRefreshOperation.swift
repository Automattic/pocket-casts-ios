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

            // Filter query ListEpisode
            let newData = DatabaseQueries.shared.filterEpisodes(filter)

            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.completion(newData)
            }
        }
    }
}
