import Foundation
import FMDB

@testable import PocketCastsDataModel

class EndOfYearManagerMock: EndOfYearDataManager {
    var listeningTimeToReturn: Double = 0

    var listenedCategoriesToReturn: [ListenedCategory] = []

    var listenedNumbersToReturn: ListenedNumbers?

    var topPodcastsToReturn: [TopPodcast] = []

    var longestEpisodeToReturn: Episode?

    var isFullListeningHistoryToReturn = false

    var yearOverYearToReturn: YearOverYearListeningTime?

    var episodesStartedAndCompleted: EpisodesStartedAndCompleted?

    override func listeningTime(dbQueue: FMDatabaseQueue) -> Double? {
        listeningTimeToReturn
    }

    override func listenedCategories(dbQueue: FMDatabaseQueue) -> [ListenedCategory] {
        listenedCategoriesToReturn
    }

    override func listenedNumbers(dbQueue: FMDatabaseQueue) -> ListenedNumbers {
        listenedNumbersToReturn ?? ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)
    }

    override func topPodcasts(dbQueue: FMDatabaseQueue, limit: Int = 5) -> [TopPodcast] {
        topPodcastsToReturn
    }

    override func longestEpisode(dbQueue: FMDatabaseQueue) -> Episode? {
        return longestEpisodeToReturn
    }

    override func isFullListeningHistory(dbQueue: FMDatabaseQueue) -> Bool {
        return isFullListeningHistoryToReturn
    }

    override func yearOverYearListeningTime(dbQueue: FMDatabaseQueue) -> YearOverYearListeningTime {
        return yearOverYearToReturn ?? YearOverYearListeningTime(totalPlayedTimeThisYear: 0, totalPlayedTimeLastYear: 0)
    }

    override func episodesStartedAndCompleted(dbQueue: FMDatabaseQueue) -> EpisodesStartedAndCompleted {
        episodesStartedAndCompleted ?? EpisodesStartedAndCompleted(started: 0, completed: 0)
    }
}
