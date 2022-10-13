import Foundation

enum FeatureFlag {
    /// Whether we should detect and show the free trial UI
    static let freeTrialsEnabled = true

    /// Whether the Tracks analytics are enabled
    static let tracksEnabled = true

    /// Whether logging of Tracks events in console are enabled
    static let tracksLoggingEnabled = false

    /// Whether logging of Firebase events in console are enabled
    static let firebaseLoggingEnabled = false

    /// Whether End Of Year feature is enabled
    static let endOfYear = false

    /// Adds the Sign In With Apple options to the login flow
    static let signInWithApple = false
}
