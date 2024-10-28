import PocketCastsDataModel
import PocketCastsServer
import SwiftUI

class EndOfYear2024StoriesModel: StoryModel {
    static let year = 2024
    var stories = [EndOfYear2024Story]()
    var data = EndOfYear2024StoriesData()

    required init() { }

    func populate(with dataManager: DataManager) {
        // First, search for top 5 podcasts
        let topPodcasts = dataManager.topPodcasts(in: Self.year, limit: 5)

        // Listening time
        if let listeningTime = dataManager.listeningTime(in: Self.year),
           listeningTime > 0, !topPodcasts.isEmpty {
            stories.append(.listeningTime)
            data.listeningTime = listeningTime
        }

    }

    func story(for storyNumber: Int) -> any StoryView {
        switch stories[storyNumber] {
        case .intro:
            return IntroStory2024()
        case .listeningTime:
            return ListeningTime2024Story(listeningTime: data.listeningTime)
        case .epilogue:
            return EpilogueStory2024()
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

    func overlaidShareView() -> AnyView? {
        nil
    }

    func footerShareView() -> AnyView? {
        AnyView(shareView())
    }

    @ViewBuilder func shareView() -> some View {
        Button(L10n.eoyShare) {
            StoriesController.shared.share()
        }
        .buttonStyle(BasicButtonStyle(textColor: .black, backgroundColor: Color.clear, borderColor: .black))
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }
}


/// An entity that holds data to present EoY 2024 stories
class EndOfYear2024StoriesData {
    var listeningTime: Double = 0
}
