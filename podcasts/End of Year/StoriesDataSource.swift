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

    /// A method to update all data from the data source.
    ///
    /// You may want to update a request, or preload images/video.
    /// Once you finished all refreshes and the data source is ready
    /// return `true`.
    func refresh() async -> Bool

    /// A view to show when paywall should be presented
    func paywallView() -> AnyView

    /// Overlaid on top of the story
    func overlaidShareView() -> AnyView?
    /// Shown at the bottom of the story as an additional safe area
    func footerShareView() -> AnyView?

    /// Color of the top Story progress indicator
    var indicatorColor: Color { get }

    /// Color of the primary background
    var primaryBackgroundColor: Color { get }

	/// Modifier applied to the sharing button
    func sharingSnapshotModifier(_ view: AnyView) -> AnyView
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

    /// Called when the story is paused
    func onPause()

    /// Called when the story is resumed after being paused
    func onResume()
}

extension Story {
    var duration: TimeInterval { EndOfYear.defaultDuration }

    var identifier: String {
        "unknown"
    }

    var plusOnly: Bool {
        false
    }

    func onAppear() {}
    func onPause() {}
    func onResume() {}
}

// MARK: - Animations

extension EnvironmentValues {
    var animated: Bool {
        get { self[AnimatedKey.self] }
        set { self[AnimatedKey.self] = newValue }
    }

    private struct AnimatedKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }
}

class PauseState: ObservableObject {
    @Published private(set) var isPaused: Bool = false

    func togglePause() {
        isPaused.toggle()
    }
}

struct PauseStateKey: EnvironmentKey {
    static let defaultValue: PauseState = PauseState()
}

extension EnvironmentValues {
    var pauseState: PauseState {
        get { self[PauseStateKey.self] }
        set { self[PauseStateKey.self] = newValue }
    }
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

    /// If the share button should be hidden for this story
    func hideShareButton() -> Bool
}

extension StorySharing {
    func willShare() {}

    func sharingAssets() -> [Any] {
        return []
    }

    func hideShareButton() -> Bool {
        false
    }
}
