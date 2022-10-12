import SwiftUI

protocol StoriesDataSource {
    var numberOfStories: Int { get }

    func story(for: Int) -> any View
    func storyView(for: Int) -> AnyView
}

extension StoriesDataSource {
    func storyView(for storyNumber: Int) -> AnyView {
        return AnyView(story(for: storyNumber))
    }
}
