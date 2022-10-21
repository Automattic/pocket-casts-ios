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

    init(dataManager: DataManager = DataManager.sharedManager) {
        self.dataManager = dataManager
    }

    // Call this method to build the list of stories and the data provider
    func build() async {

    }
}
