import Foundation
import PocketCastsDataModel

/// The available stories for EoY
enum EndOfYearStory {
    case intro
    case listeningTime
    case listenedCategories
    case topFiveCategories
    case listenedNumbers
    case topOnePodcast
    case topFivePodcasts
    case longestEpisode
    case epilogue
}

/// Build the list of stories for End of Year alongside the data
class EndOfYearStoriesBuilder {
    private let dataManager: DataManager

    private var stories: [EndOfYearStory] = []

    private let data = EndOfYearStoriesData()

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    // Call this method to build the list of stories and the data provider
    func build() async -> ([EndOfYearStory], EndOfYearStoriesData) {
        await withCheckedContinuation { continuation in
            // Listening time
            if let listeningTime = dataManager.listeningTime(),
                listeningTime > 0 {
                stories.append(.listeningTime)
                data.listeningTime = listeningTime
            }

            // Listened categories
            let listenedCategories = dataManager.listenedCategories()
            if !listenedCategories.isEmpty {
                data.listenedCategories = listenedCategories
                stories.append(.listenedCategories)
                stories.append(.topFiveCategories)
            }

            // Listened podcasts and episodes
            let listenedNumbers = dataManager.listenedNumbers()
            if listenedNumbers.numberOfEpisodes > 0
                && listenedNumbers.numberOfPodcasts > 0 {
                data.listenedNumbers = listenedNumbers
                stories.append(.listenedNumbers)
            }

            // Top podcasts
            let topPodcasts = dataManager.topPodcasts()
            if !topPodcasts.isEmpty {
                data.topPodcasts = topPodcasts
                stories.append(.topOnePodcast)
            }

            continuation.resume(returning: (stories, data))
        }
    }
}

/// An entity that holds data to present EoY stories
class EndOfYearStoriesData {
    var listeningTime: Double = 0

    var listenedCategories: [ListenedCategory] = []

    var listenedNumbers: ListenedNumbers!

    var topPodcasts: [TopPodcast] = []
}
