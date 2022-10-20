import Foundation

/// Used to configure how Stories are presented
struct StoriesConfiguration {
    /// If set to `true` it will replay the stories after the last one finished
    /// Otherwise, it will just pause on the last one.
    let startOverFromBeginningAfterFinished: Bool
}
