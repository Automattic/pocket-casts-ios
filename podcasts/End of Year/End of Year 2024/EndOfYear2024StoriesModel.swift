import PocketCastsDataModel
import PocketCastsServer

class EndOfYear2024StoriesModel: StoryModel {
    static let year = 2024
    var stories = [EndOfYear2024Story]()
    var data = EndOfYear2024StoriesData()

    required init() { }

    func populate(with dataManager: DataManager) {
        stories.append(.topSpot)
    }

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory2024()
        case .topSpot:
            return TopSpotStory2024()
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
        if stories.isEmpty {
            return false
        }

        stories.append(.intro)
        stories.append(.epilogue)

        stories.sortByCaseIterableIndex()

        return true
    }

    var numberOfStories: Int {
        stories.count
    }
}


/// An entity that holds data to present EoY 2024 stories
class EndOfYear2024StoriesData {
}
