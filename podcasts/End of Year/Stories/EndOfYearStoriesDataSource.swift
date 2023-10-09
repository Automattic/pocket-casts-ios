import SwiftUI
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
        case .listenedCategories:
            return ListenedCategoriesStory(listenedCategories: data.listenedCategories.reversed())
        case .topCategories:
            return TopListenedCategoriesStory(listenedCategories: data.listenedCategories)
        case .numberOfPodcastsAndEpisodesListened:
            return ListenedNumbersStory(listenedNumbers: data.listenedNumbers, podcasts: data.top10Podcasts)
        case .topOnePodcast:
            return TopOnePodcastStory(podcasts: data.topPodcasts)
        case .topFivePodcasts:
            return TopFivePodcastsStory(podcasts: data.topPodcasts.map { $0.podcast })
        case .longestEpisode:
            return LongestEpisodeStory(episode: data.longestEpisode, podcast: data.longestEpisodePodcast)
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
}

extension [EndOfYearStory] {
    mutating func sort() {
        let allCases = EndOfYearStory.allCases
        self = sorted { allCases.firstIndex(of: $0) ?? 0 < allCases.firstIndex(of: $1) ?? 0 }
    }
}
