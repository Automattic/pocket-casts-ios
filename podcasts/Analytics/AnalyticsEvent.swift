import Foundation

enum AnalyticsEvent: String {
    // MARK: - App Lifecycle

    case applicationInstalled
    case applicationOpened
    case applicationUpdated
    case applicationClosed

    // MARK: - User Lifecycle

    case userSignedIn
    case userSignedOut
    case userSignInFailed
    case userAccountCreated
    case userAccountCreationFailed
    case userAccountDeleted
    case userEmailUpdated
    case userPasswordUpdated
    case userPasswordReset

    // MARK: - Payment Events

    case purchaseSuccessful
    case purchaseFailed
    case purchaseCancelled

    // MARK: - Plus Upsell Dialog

    case plusPromotionShown
    case plusPromotionDismissed
    case plusPromotionUpgradeButtonTapped

    // MARK: - Setup Account

    case setupAccountShown
    case setupAccountDismissed
    case setupAccountButtonTapped

    // MARK: - Sign in View

    case signInShown
    case signInDismissed

    // MARK: - Select Account Type

    case selectAccountTypeShown
    case selectAccountTypeDismissed
    case selectAccountTypeNextButtonTapped

    // MARK: - Create Account

    case createAccountShown
    case createAccountDismissed
    case createAccountNextButtonTapped

    // MARK: - Terms of Use

    case termsOfUseShown
    case termsOfUseDismissed
    case termsOfUseAccepted
    case termsOfUseRejected

    // MARK: - Select Payment Frequency

    case selectPaymentFrequencyShown
    case selectPaymentFrequencyDismissed
    case selectPaymentFrequencyNextButtonTapped

    // MARK: - Confirm Payment

    case confirmPaymentShown
    case confirmPaymentDismissed
    case confirmPaymentConfirmButtonTapped

    // MARK: - Podcasts List

    case podcastsListShown
    case podcastsListFolderButtonTapped
    case podcastsListPodcastTapped
    case podcastsListFolderTapped
    case podcastsListOptionsButtonTapped
    case podcastsListReordered
    case podcastsListModalOptionTapped
    case podcastsListSortOrderChanged
    case podcastsListLayoutChanged
    case podcastsListBadgesChanged

    // MARK: - Newsletter Opt In

    case newsletterOptInChanged

    // MARK: - Forgot Password

    case forgotPasswordShown
    case forgotPasswordDismissed

    // MARK: - Account Updated View

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
    
    // MARK: - Folders

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

    // MARK: - Playback

    case play
    case pause
    case skipBack
    case skipForward

    // MARK: - Filters

    case filterListShown
    case filterListEditButtonToggled
    case filterListReordered

    case filterDeleted
    case filterUpdated
    case filterCreated

    case filterShown

    case filterMultiSelectEntered
    case filterSelectAllButtonTapped
    case filterMultiSelectExited

    case filterOptionsButtonTapped
    case filterOptionsModalOptionTapped
    case filterSortByChanged
    case filterEditDismissed

    case filterSiriShortcutsShown
    case filterSiriShortcutAdded
    case filterSiriShortcutRemoved

    // MARK: - Podcast screen

    case podcastScreenShown
    case podcastScreenFolderTapped
    case podcastScreenSettingsTapped
    case podcastScreenSubscribeTapped
    case podcastScreenUnsubscribeTapped
    case podcastScreenSearchPerformed
    case podcastScreenSearchCleared
    case podcastScreenOptionsTapped
    case podcastScreenToggleArchived
    case podcastScreenShareTapped
    case podcastScreenToggleSummary

    // MARK: - App Store Review Request

    case appStoreReviewRequested

    // MARK: - Signed out alert

    case signedOutAlertShown

    // MARK: - Discover

    case discoverShown
    case discoverCategoryShown
    case discoverFeaturedPodcastTapped
    case discoverShowAllTapped

    case discoverListImpression
    case discoverListShowAllTapped
    case discoverListEpisodeTapped
    case discoverListEpisodePlay
    case discoverListPodcastTapped
    case discoverListPodcastSubscribed

    case discoverPagedListPageChanged
}
