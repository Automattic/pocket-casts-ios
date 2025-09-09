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

    override func listeningTime(in year: Int, dbQueue: PCDBQueue) -> Double? {
        listeningTimeToReturn
    }

    override func listenedCategories(in year: Int, dbQueue: PCDBQueue) -> [ListenedCategory] {
        listenedCategoriesToReturn
    }

    override func listenedNumbers(in year: Int, dbQueue: PCDBQueue) -> ListenedNumbers {
        listenedNumbersToReturn ?? ListenedNumbers(numberOfPodcasts: 0, numberOfEpisodes: 0)
    }

    override func topPodcasts(in year: Int, dbQueue: PCDBQueue, limit: Int = 5) -> [TopPodcast] {
        topPodcastsToReturn
    }

    override func longestEpisode(in year: Int, dbQueue: PCDBQueue) -> Episode? {
        return longestEpisodeToReturn
    }

    override func isFullListeningHistory(in year: Int, dbQueue: PCDBQueue) -> Bool {
        return isFullListeningHistoryToReturn
    }

    override func yearOverYearListeningTime(in year: Int, dbQueue: PCDBQueue) -> YearOverYearListeningTime {
        return yearOverYearToReturn ?? YearOverYearListeningTime(totalPlayedTimeThisYear: 0, totalPlayedTimeLastYear: 0)
    }

    override func episodesStartedAndCompleted(in year: Int, dbQueue: PCDBQueue) -> EpisodesStartedAndCompleted {
        episodesStartedAndCompleted ?? EpisodesStartedAndCompleted(started: 0, completed: 0)
    }
}
