import DifferenceKit
import Foundation
import PocketCastsDataModel

class PodcastEpisodesRefreshOperation: Operation {
    private let episodesDataManager: EpisodesDataManager
    private let podcast: Podcast
    private let uuidsToFilter: [String]?
    private let completion: (([ArraySection<String, ListItem>]) -> Void)?

    init(episodesDataManager: EpisodesDataManager = EpisodesDataManager(), podcast: Podcast, uuidsToFilter: [String]?, completion: (([ArraySection<String, ListItem>]) -> Void)?) {
        self.episodesDataManager = episodesDataManager
        self.podcast = podcast
        self.uuidsToFilter = uuidsToFilter
        self.completion = completion

        super.init()
    }

    override func main() {
        autoreleasepool {
            if self.isCancelled { return }

            let newData: [ArraySection<String, ListItem>] = episodesDataManager.get(.podcast(podcast, uuidsToFilter: uuidsToFilter))

            if self.isCancelled { return }
            DispatchQueue.main.sync { [weak self] in
                guard let strongSelf = self else { return }

                if strongSelf.isCancelled { return }

                strongSelf.completion?(newData)
            }
        }
    }

    func createEpisodesQuery() -> String {
        episodesDataManager.createEpisodesQuery(podcast, uuidsToFilter: uuidsToFilter)
    }
}
