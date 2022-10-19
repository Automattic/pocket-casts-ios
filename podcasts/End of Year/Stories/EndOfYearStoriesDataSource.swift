import SwiftUI
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 2

    let randomPodcasts = DataManager.sharedManager.randomPodcasts()

    var listeningTime: Double?

    func story(for storyNumber: Int) -> any StoryView {
        switch storyNumber {
        case 0:
            return DummyStory(podcasts: randomPodcasts)
        default:
            return FakeStory()
        }
    }

    func isReady() async -> Bool {
        await withCheckedContinuation { continuation in
            self.listeningTime = DataManager.sharedManager.listeningTime()

            continuation.resume(returning: true)
        }
    }
}

struct FakeStory: StoryView {
    var duration: TimeInterval = 5.seconds

    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}
