import Foundation

/// Used to configure how Stories are presented
class StoriesConfiguration {
    /// If set to `true` it will replay the stories after the last one finished
    /// Otherwise, it will just pause on the last one.
    ///
    /// Default value is `false`
    var startOverFromBeginningAfterFinished: Bool = false

    /// The number of stories to preload
    ///
    /// When showing the story number zero, StoriesView will
    /// try to load the next `storiesToPreload` number, so any
    /// images or other assets can start loading before it's
    /// actually shown.
    var storiesToPreload: Int = 2

    var shouldShowDismissButton: Bool = true

    var indicatorHeight: CGFloat = 2

    var indicatorSpacing: CGFloat = 2
}
