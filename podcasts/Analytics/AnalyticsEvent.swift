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
    case plusPromotionViewShown
    case plusPromotionViewDismissed
    case plusPromotionUpgradeButtonTapped

    // Setup Account
    case setupAccountViewShown
    case setupAccountViewDismissed
    case setupAccountViewButtonTapped

    // Sign in View
    case signInViewShown
    case signInViewDismissed

    // Select Account Type
    case selectAccountTypeViewShown
    case selectAccountTypeViewDismissed
    case selectAccountTypeViewNextButtonTapped

    // Create Account
    case createAccountViewShown
    case createAccountViewDismissed
    case createAccountViewNextButtonTapped

    // Terms of Use
    case termsOfUseViewShown
    case termsOfUseViewDismissed
    case termsOfUseViewAccepted
    case termsOfUseViewRejected

    // Select Payment Frequency
    case selectPaymentFrequencyViewShown
    case selectPaymentFrequencyViewDismissed
    case selectPaymentFrequencyViewNextButtonTapped

    // Confirm Payment
    case confirmPaymentViewShown
    case confirmPaymentViewDismissed
    case confirmPaymentViewConfirmButtonTapped
}
