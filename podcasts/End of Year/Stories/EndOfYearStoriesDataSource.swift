import SwiftUI
import PocketCastsDataModel

struct EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 2

    let randomPodcasts = DataManager.sharedManager.randomPodcasts()

    @ViewBuilder
    func story(for storyNumber: Int) -> any View {
        switch storyNumber {
        case 0:
            DummyStory(podcasts: randomPodcasts)
        default:
            FakeStoryTwo()
        }
    }

    func isReady() async -> Bool {
        true
    }
}

struct FakeStory: View {
    var body: some View {
        ZStack {
            Color.purple
        }
    }
}

struct FakeStoryTwo: View {
    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}
