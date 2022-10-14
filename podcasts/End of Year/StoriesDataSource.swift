import SwiftUI

protocol StoriesDataSource {
    var numberOfStories: Int { get }

    func story(for: Int) -> any View
    func storyView(for: Int) -> AnyView

    /// Whether the data source is ready to be used.
    ///
    /// You may want to make a request, or preload images/video.
    /// Once you finished any task and the data source is ready
    /// return `true`.
    func isReady() async -> Bool
}

extension StoriesDataSource {
    func storyView(for storyNumber: Int) -> AnyView {
        return AnyView(story(for: storyNumber))
    }
}
