import Foundation

enum FeatureFlag {
    /// Whether we should detect and show the free trial UI
    static let freeTrialsEnabled = false

    /// Whether the Tracks analytics are enabled
    static let tracksEnabled = false

    /// Whether logging of Firebase events in console is enabled
    static let firebaseLoggingEnabled = false
}
