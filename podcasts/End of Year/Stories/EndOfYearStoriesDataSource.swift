import SwiftUI
import PocketCastsServer
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var model: StoryModel

    init(model: StoryModel) {
        self.model = model
    }

    var numberOfStories: Int {
        model.numberOfStories
    }

    func story(for storyNumber: Int) -> any StoryView {
        model.story(for: storyNumber)
    }

    func shareableStory(for storyNumber: Int) -> (any ShareableStory)? {
        story(for: storyNumber) as? (any ShareableStory)
    }

    /// The only interactive view we have is the last one, with the replay button
    func isInteractiveView(for storyNumber: Int) -> Bool {
        model.isInteractiveView(for: storyNumber)
    }

    func isReady() async -> Bool {
        await EndOfYearStoriesBuilder(model: model).build()

        return model.isReady()
    }

    func refresh() async -> Bool {
        Settings.setHasSyncedEpisodesForPlayback(false, year: type(of: model).year)

        await SyncYearListeningProgress.shared.reset()

        return await isReady()
    }
}

extension Array where Element: CaseIterable & Equatable {
    mutating func sortByCaseIterableIndex() {
        let allCases = Element.allCases
        self = sorted {
            guard let firstIndex0 = allCases.firstIndex(of: $0),
                  let firstIndex1 = allCases.firstIndex(of: $1) else {
                return false
            }
            return firstIndex0 < firstIndex1
        }
    }
}
