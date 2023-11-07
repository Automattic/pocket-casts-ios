import SwiftUI

protocol StoriesDataSource {
    var numberOfStories: Int { get }

    func story(for: Int) -> any StoryView
    func storyView(for: Int) -> AnyView

    /// Returns a story that supports being shared, or nil if it doesn't
    func shareableStory(for: Int) -> (any ShareableStory)?

    /// This determines whether or not the story has interactivity
    ///
    /// This allows having interactive elements, such as buttons.
    /// It's up to the view to control `allowsHitTesting`. So make
    /// sure that your story doesn't entirely block user interactions.
    func isInteractiveView(for: Int) -> Bool

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

    func isInteractiveView(for: Int) -> Bool {
        return false
    }
}

// MARK: - Story Views
typealias StoryView = Story & View

protocol Story {
    /// The amount of time this story should be show
    var duration: TimeInterval { get }

    /// A string that identifies the story
    var identifier: String { get }

    /// If the story is available only for Plus users
    var plusOnly: Bool { get }

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
    var identifier: String {
        "unknown"
    }

    var plusOnly: Bool {
        false
    }

    func onAppear() {}
}

// MARK: - Shareable Stories
typealias ShareableStory = StoryView & StorySharing

protocol StorySharing {
    /// Called when the story will be shared
    func willShare()

    /// Called to get the story shareable assets
    ///
    /// This will be given to `UIActivityViewController` as the `activityItems`
    func sharingAssets() -> [Any]
}

extension StorySharing {
    func willShare() {}

    func sharingAssets() -> [Any] {
        return []
    }
}
