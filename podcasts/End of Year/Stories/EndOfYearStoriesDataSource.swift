import SwiftUI
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 3

    let randomPodcasts = DataManager.sharedManager.randomPodcasts()

    var listeningTime: Double?

    var listenedCategories: [ListenedCategory] = []

    func story(for storyNumber: Int) -> any StoryView {
        switch storyNumber {
        case 0:
            return ListeningTimeStory(listeningTime: listeningTime!)
        case 1:
            return ListenedCategoriesStory(listenedCategories: listenedCategories)
        default:
            return DummyStory(podcasts: randomPodcasts)
        }
    }

    func isReady() async -> Bool {
        await withCheckedContinuation { continuation in
            self.listeningTime = DataManager.sharedManager.listeningTime()

            self.listenedCategories = DataManager.sharedManager.listenedCategories()

            continuation.resume(returning: true)
        }
    }
}
