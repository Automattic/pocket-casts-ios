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

    // Payment Events
    case purchaseSuccessful
    case purchaseFailed
    case purchaseCancelled

    // Plus Upsell Dialog
    case plusPromotionViewAccessed
    case plusPromotionViewDismissed
    case plusPromotionUpgradeButtonTapped

    // Setup Account
    case setupAccountViewAccessed
    case setupAccountViewDismissed
    case setupAccountViewButtonTapped

    // Sign in View
    case signInViewAccessed
    case signInViewDismissed
}
