import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int {
        stories.count
    }

    var stories: [EndOfYearStory] = []

    var data: EndOfYearStoriesData!

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory()
        case .listeningTime:
            return ListeningTimeStory(listeningTime: data.listeningTime, podcasts: data.top10Podcasts)
        case .topCategories:
            return TopListenedCategoriesStory(listenedCategories: data.listenedCategories)
        case .numberOfPodcastsAndEpisodesListened:
            return ListenedNumbersStory(listenedNumbers: data.listenedNumbers, podcasts: data.top10Podcasts)
        case .topOnePodcast:
            return TopOnePodcastStory(podcasts: data.topPodcasts)
        case .topFivePodcasts:
            return TopFivePodcastsStory(topPodcasts: data.topPodcasts)
        case .longestEpisode:
            return LongestEpisodeStory(episode: data.longestEpisode, podcast: data.longestEpisodePodcast)
        case .yearOverYearListeningTime:
            return YearOverYearStory(data: data.yearOverYearListeningTime)
        case .completionRate:
            return CompletionRateStory(subscriptionTier: SubscriptionHelper.activeTier, startedAndCompleted: data.episodesStartedAndCompleted)
        case .epilogue:
            return EpilogueStory()
        }
    }

    func shareableStory(for storyNumber: Int) -> (any ShareableStory)? {
        story(for: storyNumber) as? (any ShareableStory)
    }

    /// The only interactive view we have is the last one, with the replay button
    func isInteractiveView(for storyNumber: Int) -> Bool {
        switch stories[storyNumber] {
        case .epilogue:
            return true
        default:
            return false
        }
    }

    func isReady() async -> Bool {
        (stories, data) = await EndOfYearStoriesBuilder().build()

        if !stories.isEmpty {
            stories.append(.intro)
            stories.append(.epilogue)

            stories.sort()

            return true
        }

        return false
    }

    func refresh() async -> Bool {
        Settings.hasSyncedEpisodesForPlayback2023 = false

        await SyncYearListeningProgress.shared.reset()

        return await isReady()
    }
}

extension [EndOfYearStory] {
    mutating func sort() {
        let allCases = EndOfYearStory.allCases
        self = sorted { allCases.firstIndex(of: $0) ?? 0 < allCases.firstIndex(of: $1) ?? 0 }
    }
}
