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
            if let listeningTime = dataManager.listeningTime(),
                listeningTime > 0 {
                stories.append(.listeningTime)
                data.listeningTime = listeningTime
            }

            continuation.resume(returning: (stories, data))
        }
    }
}

/// An entity that holds data to present EoY stories
class EndOfYearStoriesData {
    var listeningTime: Double = 0
}
