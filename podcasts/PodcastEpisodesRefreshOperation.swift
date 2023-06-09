import DifferenceKit
import Foundation
import PocketCastsDataModel

class PodcastEpisodesRefreshOperation: Operation {
    private let podcast: Podcast
    private let uuidsToFilter: [String]?
    private let completion: (([ArraySection<String, ListItem>]) -> Void)?

    init(podcast: Podcast, uuidsToFilter: [String]?, completion: (([ArraySection<String, ListItem>]) -> Void)?) {
        self.podcast = podcast
        self.uuidsToFilter = uuidsToFilter
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            // the podcast page has a header, for simplicity in table animations, we add it here
            let searchHeader = ListHeader(headerTitle: L10n.search, isSectionHeader: true)
            let newData = DatabaseQueries.shared.podcastEpisodes(podcast, uuidsToFilter: uuidsToFilter)

            if self.isCancelled { return }
            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                if strongSelf.isCancelled { return }

                strongSelf.completion?(newData)
            }
        }
    }

    func createEpisodesQuery() -> String {
        let sortStr: String
        let sortOrder = PodcastEpisodeSortOrder(rawValue: podcast.episodeSortOrder) ?? PodcastEpisodeSortOrder.newestToOldest
        switch sortOrder {
        case .newestToOldest:
            sortStr = "ORDER BY publishedDate DESC, addedDate DESC"
        case .oldestToNewest:
            sortStr = "ORDER BY publishedDate ASC, addedDate ASC"
        case .shortestToLongest:
            sortStr = "ORDER BY duration ASC, addedDate"
        case .longestToShortest:
            sortStr = "ORDER BY duration DESC, addedDate"
        }
        if let uuids = uuidsToFilter {
            let inClause = "(\(uuids.map { "'\($0)'" }.joined(separator: ",")))"
            return "podcast_id = \(podcast.id) AND uuid IN \(inClause) \(sortStr)"
        }
        if !podcast.showArchived {
            return "podcast_id = \(podcast.id) AND archived = 0 \(sortStr)"
        }

        return "podcast_id = \(podcast.id) \(sortStr)"
    }
}
