import Foundation

enum AnalyticsEvent: String {
    // App Lifecycle
    case applicationInstalled
    case applicationOpened
    case applicationUpdated
    case applicationClosed

    // User Lifecycle
    case userSignedIn
    case userSignedOut
    case userSignInFailed
    case userAccountCreated
    case userAccountCreationFailed
    case userAccountDeleted
    case userEmailUpdated
    case userPasswordUpdated
    case userPasswordReset
}
