import PocketCastsDataModel
import PocketCastsServer

class EndOfYear2023StoriesModel: StoryModel {
    static let year = 2023
    var stories = [EndOfYear2023Story]()
    var data = EndOfYear2023StoriesData()

    required init() {}

    func populate(with dataManager: DataManager) {
        // First, search for top 10 podcasts to use throughout different stories
        let topPodcasts = dataManager.topPodcasts(in: Self.year, limit: 10)
        if !topPodcasts.isEmpty {
            data.topPodcasts = Array(topPodcasts.prefix(5))
            data.top10Podcasts = Array(topPodcasts.suffix(8)).map { $0.podcast }.reversed()
        }

        // Listening time
        if let listeningTime = dataManager.listeningTime(in: Self.year),
           listeningTime > 0, !data.top10Podcasts.isEmpty {
            stories.append(.listeningTime)
            data.listeningTime = listeningTime
        }

        // Listened categories
        let listenedCategories = dataManager.listenedCategories(in: Self.year)
        if !listenedCategories.isEmpty {
            data.listenedCategories = listenedCategories
            stories.append(.topCategories)
        }

        // Listened podcasts and episodes
        let listenedNumbers = dataManager.listenedNumbers(in: Self.year)
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
        if let longestEpisode = dataManager.longestEpisode(in: Self.year),
           let podcast = longestEpisode.parentPodcast() {
            data.longestEpisode = longestEpisode
            data.longestEpisodePodcast = podcast
            stories.append(.longestEpisode)
        }

        // Year over year listening time
        let yearOverYearListeningTime = dataManager.yearOverYearListeningTime(in: Self.year)
        if yearOverYearListeningTime.totalPlayedTimeThisYear != 0 ||
            yearOverYearListeningTime.totalPlayedTimeLastYear != 0 {
            data.yearOverYearListeningTime = yearOverYearListeningTime
            stories.append(.yearOverYearListeningTime)
        }

        data.episodesStartedAndCompleted = dataManager.episodesStartedAndCompleted(in: Self.year)
        stories.append(.completionRate)
    }

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory2023()
        case .listeningTime:
            return ListeningTimeStory2023(listeningTime: data.listeningTime, podcasts: data.top10Podcasts)
        case .topCategories:
            return TopListenedCategoriesStory2023(listenedCategories: data.listenedCategories)
        case .numberOfPodcastsAndEpisodesListened:
            return ListenedNumbersStory2023(listenedNumbers: data.listenedNumbers, podcasts: data.top10Podcasts)
        case .topOnePodcast:
            return TopOnePodcastStory2023(podcasts: data.topPodcasts)
        case .topFivePodcasts:
            return TopFivePodcastsStory2023(topPodcasts: data.topPodcasts)
        case .longestEpisode:
            return LongestEpisodeStory2023(episode: data.longestEpisode, podcast: data.longestEpisodePodcast)
        case .yearOverYearListeningTime:
            return YearOverYearStory2023(data: data.yearOverYearListeningTime)
        case .completionRate:
            return CompletionRateStory2023(subscriptionTier: SubscriptionHelper.activeTier, startedAndCompleted: data.episodesStartedAndCompleted)
        case .epilogue:
            return EpilogueStory2023()
        }
    }

    func isInteractiveView(for storyNumber: Int) -> Bool {
        switch stories[storyNumber] {
        case .epilogue:
            return true
        default:
            return false
        }
    }

    func isReady() -> Bool {
        if !stories.isEmpty {
            stories.append(.intro)
            stories.append(.epilogue)

            stories.sortByCaseIterableIndex()

            return true
        }

        return false
    }

    var numberOfStories: Int {
        stories.count
    }
}

/// An entity that holds data to present EoY 2023 stories
class EndOfYear2023StoriesData {
    var listeningTime: Double = 0

    var listenedCategories: [ListenedCategory] = []

    var listenedNumbers: ListenedNumbers!

    var topPodcasts: [TopPodcast] = []

    var longestEpisode: Episode!

    var longestEpisodePodcast: Podcast!

    var top10Podcasts: [Podcast] = []

    var yearOverYearListeningTime: YearOverYearListeningTime!

    var episodesStartedAndCompleted: EpisodesStartedAndCompleted!
}
