import Foundation
import PocketCastsDataModel
import PocketCastsServer

/// The available stories for EoY
/// Order is important, as the stories will be displayed
/// in the order listed here.
enum EndOfYearStory: CaseIterable {
    case intro
    case numberOfPodcastsAndEpisodesListened
    case topOnePodcast
    case topFivePodcasts
    case listeningTime
    case listenedCategories
    case topCategories
    case longestEpisode
    case epilogue
}

/// Build the list of stories for End of Year alongside the data
class EndOfYearStoriesBuilder {
    private let dataManager: DataManager

    private var stories: [EndOfYearStory] = []

    private let data = EndOfYearStoriesData()

    private let sync: (() -> Bool)?

    init(dataManager: DataManager = DataManager.sharedManager, sync: (() -> Bool)? = YearListeningHistory.sync) {
        self.dataManager = dataManager
        self.sync = sync
    }

    /// Call this method to build the list of stories and the data provider
    func build() async -> ([EndOfYearStory], EndOfYearStoriesData) {
        await withCheckedContinuation { continuation in

            // Check if the user has the full listening history for this year
            if SyncManager.isUserLoggedIn(), !Settings.hasSyncedAll2022Episodes {
                let syncedWithSuccess = sync?()

                if syncedWithSuccess == true {
                    Settings.hasSyncedAll2022Episodes = true
                } else {
                    continuation.resume(returning: ([], data))
                    return
                }
            }

            // First, search for top 10 podcasts to use throughout different stories
            let topPodcasts = dataManager.topPodcasts(limit: 10)
            if !topPodcasts.isEmpty {
                data.topPodcasts = Array(topPodcasts.prefix(5))
                data.top10Podcasts = Array(topPodcasts.suffix(8)).map { $0.podcast }.reversed()
            }

            // Listening time
            if let listeningTime = dataManager.listeningTime(),
               listeningTime > 0, !data.top10Podcasts.isEmpty {
                stories.append(.listeningTime)
                data.listeningTime = listeningTime
            }

            // Listened categories
            let listenedCategories = dataManager.listenedCategories()
            if !listenedCategories.isEmpty {
                data.listenedCategories = listenedCategories
                stories.append(.listenedCategories)
                stories.append(.topCategories)
            }

            // Listened podcasts and episodes
            let listenedNumbers = dataManager.listenedNumbers()
            if listenedNumbers.numberOfEpisodes > 0
                && listenedNumbers.numberOfPodcasts > 0
                && !data.top10Podcasts.isEmpty {
                data.listenedNumbers = listenedNumbers
                stories.append(.numberOfPodcastsAndEpisodesListened)
            }

            // Top podcasts
            if !data.topPodcasts.isEmpty {
                stories.append(.topOnePodcast)
            }

            // Top 5 podcasts
            if topPodcasts.count > 1 {
                stories.append(.topFivePodcasts)
            }

            // Longest episode
            if let longestEpisode = dataManager.longestEpisode(),
               let podcast = longestEpisode.parentPodcast() {
                data.longestEpisode = longestEpisode
                data.longestEpisodePodcast = podcast
                stories.append(.longestEpisode)
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

    var longestEpisode: Episode!

    var longestEpisodePodcast: Podcast!

    var top10Podcasts: [Podcast] = []
}
