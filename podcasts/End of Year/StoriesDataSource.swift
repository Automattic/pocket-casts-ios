import SwiftUI

protocol StoriesDataSource {
    var numberOfStories: Int { get }

    func story(for: Int) -> any StoryView
    func storyView(for: Int) -> AnyView

    /// An interactive view that is put on top of the Stories control
    ///
    /// This allows having interactive elements, such as buttons.
    /// It's up to the view to control `allowsHitTesting`. So make
    /// sure that your story doesn't entirely block user interactions.
    func interactiveView(for: Int) -> AnyView

    /// Whether the data source is ready to be used.
    ///
    /// You may want to make a request, or preload images/video.
    /// Once you finished any task and the data source is ready
    /// return `true`.
    func isReady() async -> Bool
}

extension StoriesDataSource {
    func storyView(for storyNumber: Int) -> AnyView {
        let story = story(for: storyNumber)
        story.onAppear()
        return AnyView(story)
    }

    func interactiveView(for: Int) -> AnyView {
        return AnyView(EmptyView())
    }

    func shareableAsset(for storyNumber: Int) -> Any {
        ZStack {
            storyView(for: storyNumber)
        }
        .frame(width: 370, height: 693)
        .snapshot()
    }
}

typealias StoryView = Story & View

protocol Story {
    /// The amount of time this story should be show
    var duration: TimeInterval { get }

    /// Called when the story actually appears.
    ///
    /// If you use SwiftUI `onAppear` together with preload
    /// you might run into `onAppear` being called while the view
    /// is not actually being displayed.
    /// This method instead will only be called when the story
    /// is being presented.
    func onAppear()
}

extension Story {
    func onAppear() {  }
}
