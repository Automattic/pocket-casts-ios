import Foundation

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

    override func listeningTime(in year: Int, dbQueue: GRDBQueue) -> Double? {
        listeningTimeToReturn
    }

    override func listenedCategories(in year: Int, dbQueue: GRDBQueue) -> [ListenedCategory] {
        listenedCategoriesToReturn
    }

    override func listenedNumbers(in year: Int, dbQueue: GRDBQueue) -> ListenedNumbers {
        listenedNumbersToReturn ?? ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)
    }

    override func topPodcasts(in year: Int, dbQueue: GRDBQueue, limit: Int = 5) -> [TopPodcast] {
        topPodcastsToReturn
    }

    override func longestEpisode(in year: Int, dbQueue: GRDBQueue) -> Episode? {
        return longestEpisodeToReturn
    }

    override func isFullListeningHistory(in year: Int, dbQueue: GRDBQueue) -> Bool {
        return isFullListeningHistoryToReturn
    }

    override func yearOverYearListeningTime(in year: Int, dbQueue: GRDBQueue) -> YearOverYearListeningTime {
        return yearOverYearToReturn ?? YearOverYearListeningTime(totalPlayedTimeThisYear: 0, totalPlayedTimeLastYear: 0)
    }

    override func episodesStartedAndCompleted(in year: Int, dbQueue: GRDBQueue) -> EpisodesStartedAndCompleted {
        episodesStartedAndCompleted ?? EpisodesStartedAndCompleted(started: 0, completed: 0)
    }
}
