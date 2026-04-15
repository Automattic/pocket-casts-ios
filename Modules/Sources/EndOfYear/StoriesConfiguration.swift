import Foundation

/// Used to configure how Stories are presented
public class StoriesConfiguration {
    /// If set to `true` it will replay the stories after the last one finished
    /// Otherwise, it will just pause on the last one.
    ///
    /// Default value is `false`
    public var startOverFromBeginningAfterFinished: Bool = false

    // If set to `true` it will close the playback after the last one finished
    /// Otherwise, it will just pause on the last one.
    ///
    /// Default value is `false`
    public var closeAndDismissAfterFinished: Bool = false

    /// The number of stories to preload
    ///
    /// When showing the story number zero, StoriesView will
    /// try to load the next `storiesToPreload` number, so any
    /// images or other assets can start loading before it's
    /// actually shown.
    public var storiesToPreload: Int = 2

    public var shouldShowDismissButton: Bool = true

    public var indicatorHeight: CGFloat = 2

    public var indicatorSpacing: CGFloat = 2

    public var loadingIsTheFirstStory: Bool = false

    public var defaultStoriesCount: Int = 7

    public init() {}
}
