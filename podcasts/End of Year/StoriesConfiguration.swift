import Foundation

/// Used to configure how Stories are presented
class StoriesConfiguration {
    /// If set to `true` it will replay the stories after the last one finished
    /// Otherwise, it will just pause on the last one.
    ///
    /// Default value is `false`
    var startOverFromBeginningAfterFinished: Bool = false
}
