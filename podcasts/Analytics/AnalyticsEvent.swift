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
    case plusPromotionShown
    case plusPromotionDismissed
    case plusPromotionUpgradeButtonTapped

    // Setup Account
    case setupAccountShown
    case setupAccountDismissed
    case setupAccountButtonTapped

    // Sign in View
    case signInShown
    case signInDismissed

    // Select Account Type
    case selectAccountTypeShown
    case selectAccountTypeDismissed
    case selectAccountTypeNextButtonTapped

    // Create Account
    case createAccountShown
    case createAccountDismissed
    case createAccountNextButtonTapped

    // Terms of Use
    case termsOfUseShown
    case termsOfUseDismissed
    case termsOfUseAccepted
    case termsOfUseRejected

    // Select Payment Frequency
    case selectPaymentFrequencyShown
    case selectPaymentFrequencyDismissed
    case selectPaymentFrequencyNextButtonTapped

    // Confirm Payment
    case confirmPaymentShown
    case confirmPaymentDismissed
    case confirmPaymentConfirmButtonTapped

    // Podcasts List
    case podcastsListShown
    case podcastsListFolderButtonTapped
    case podcastsListPodcastTapped
    case podcastsListFolderTapped
    case podcastsListOptionsButtonTapped
    case podcastsListReordered

    // Newsletter Opt In
    case newsletterOptInChanged

    // Forgot Password
    case forgotPasswordShown
    case forgotPasswordDismissed

    // Account Updated View
    case accountUpdatedShown
    case accountUpdatedDismissed

    // MARK: - Table Swipe Actions for Podcast episodes

    case episodeSwipeActionPerformed

    // MARK: - Profile View

    case profileShown
    case profileSettingsButtonTapped
    case profileAccountButtonTapped
    case profileRefreshButtonTapped

    // MARK: - Stats View

    case statsShown
    case statsDismissed
    
    // Folder
    case folderShown
    case folderCreateShown
    case folderPodcastPickerSearchPerformed
    case folderPodcastPickerSearchCleared
    case folderPodcastPickerFilterChanged
    case folderCreateNameShown
    case folderCreateColorShown
    case folderSaved
    case folderChoosePodcastsShown
    case folderChoosePodcastsDismissed
    case folderAddPodcastsButtonTapped
    case folderOptionsButtonTapped
    case folderSortByChanged
    case folderOptionsModalOptionTapped
    case folderEditShown
    case folderEditDismissed
    case folderEditDeleteButtonTapped
    case folderDeleted
    case folderChooseShown
    case folderChooseFolderTapped
    case folderChooseRemovedFromFolder
    case folderPodcastModalOptionTapped

    // MARK: - Tab Bar Items

    case podcastTabOpened
    case filtersTabOpened
    case discoverTabOpened
    case profileTabOpened

    // MARK: - Downloads View

    case downloadsShown
    case downloadsOptionsButtonTapped
    case downloadsOptionsModalOptionTapped

    case downloadsMultiSelectEntered
    case downloadsSelectAllButtonTapped
    case downloadsMultiSelectExited

    // MARK: - Downloads Clean Up View

    case downloadsCleanUpShown
    case downloadsCleanUpButtonTapped
    case downloadsCleanUpCompleted

    // MARK: - Listening History

    case listeningHistoryShown
    case listeningHistoryOptionsButtonTapped
    case listeningHistoryOptionsModalOptionTapped

    case listeningHistoryMultiSelectEntered
    case listeningHistorySelectAllButtonTapped
    case listeningHistoryMultiSelectExited

    case listeningHistoryCleared

    // MARK: - Uploaded Files

    case uploadedFilesShown
    case uploadedFilesOptionsButtonTapped
    case uploadedFilesOptionsModalOptionTapped

    case uploadedFilesMultiSelectEntered
    case uploadedFilesSelectAllButtonTapped
    case uploadedFilesMultiSelectExited

    case uploadedFilesSortByChanged
    case uploadedFilesHelpButtonTapped

    // MARK: - User File Details View

    case userFileDeleted
    case userFileDetailShown
    case userFileDetailDismissed
    case userFileDetailOptionTapped

    case userFilePlayPauseButtonTapped

    // MARK: - Starred

    case starredShown
    case starredMultiSelectEntered
    case starredSelectAllButtonTapped
    case starredMultiSelectExited

    // MARK: - Podcast screen

    case podcastScreenShown
    case podcastScreenFolderTapped
    case podcastScreenSettingsTapped
    case podcastScreenSubscribeTapped
    case podcastScreenUnsubscribeTapped
    case podcastScreenSearchPerformed
    case podcastScreenSearchCleared
}
