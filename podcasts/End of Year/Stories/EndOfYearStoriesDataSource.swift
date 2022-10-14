import SwiftUI
import PocketCastsDataModel

struct EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 2

    let mostListenedPodcats = DataManager.sharedManager.mostListenedPodcasts()

    @ViewBuilder
    func story(for storyNumber: Int) -> any View {
        switch storyNumber {
        case 0:
            DummyStory()
        default:
            FakeStoryTwo()
        }
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
