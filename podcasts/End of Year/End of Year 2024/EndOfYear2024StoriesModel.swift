import PocketCastsDataModel
import PocketCastsServer

class EndOfYear2024StoriesModel: StoryModel {
    let year = 2024
    var stories = [EndOfYear2024Story]()
    var data = EndOfYear2024StoriesData()

    func populate(with dataManager: DataManager) {
        // Will be implemented in a future PR
    }

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory()
        case .epilogue:
            return EpilogueStory()
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


/// An entity that holds data to present EoY 2024 stories
class EndOfYear2024StoriesData {
}
