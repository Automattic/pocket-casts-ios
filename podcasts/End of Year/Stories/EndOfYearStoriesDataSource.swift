import SwiftUI
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 9

    var listeningTime: Double?

    var listenedCategories: [ListenedCategory] = []

    var listenedNumbers: ListenedNumbers?

    var topPodcasts: [TopPodcast] = []

    var longestEpisode: Episode?

    func story(for storyNumber: Int) -> any StoryView {
        switch storyNumber {
        case 0:
            return IntroStory()
        case 1:
            return ListeningTimeStory(listeningTime: listeningTime!)
        case 2:
            return ListenedCategoriesStory(listenedCategories: listenedCategories)
        case 3:
            return TopListenedCategories(listenedCategories: listenedCategories)
        case 4:
            return ListenedNumbersStory(listenedNumbers: listenedNumbers!)
        case 5:
            return TopOnePodcastStory(topPodcast: topPodcasts[0])
        case 6:
            return TopFivePodcastsStory(podcasts: topPodcasts.map { $0.podcast })
        case 7:
            return LongestEpisodeStory(episode: longestEpisode!, podcast: longestEpisode!.parentPodcast()!)
        default:
            return EpilogueStory()
        }
    }

    /// The only interactive view we have is the last one, with the replay button
    func interactiveView(for storyNumber: Int) -> AnyView {
        storyNumber == 8 ? AnyView(EpilogueStory()) : AnyView(EmptyView())
    }

    func isReady() async -> Bool {
        await withCheckedContinuation { continuation in
            self.listeningTime = DataManager.sharedManager.listeningTime()

            self.listenedCategories = DataManager.sharedManager.listenedCategories()

            self.listenedNumbers = DataManager.sharedManager.listenedNumbers()

            self.topPodcasts = DataManager.sharedManager.topPodcasts()

            self.longestEpisode = DataManager.sharedManager.longestEpisode()

            continuation.resume(returning: true)
        }
    }
}
