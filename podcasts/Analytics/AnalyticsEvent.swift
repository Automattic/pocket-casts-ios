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
    case ssoStarted

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

    case accountDetailsCancelTapped
    case accountDetailsShowTOS
    case accountDetailsShowPrivacyPolicy

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

    case podcastsTabOpened
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

    case playbackPlay
    case playbackPause
    case playbackSkipBack
    case playbackSkipForward
    case playbackSeek

    case playbackEffectSpeedChanged
    case playbackEffectTrimSilenceToggled
    case playbackEffectTrimSilenceAmountChanged
    case playbackEffectVolumeBoostToggled

    case playbackEpisodeAutoplayed

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
    case podcastsScreenSortOrderChanged
    case podcastsScreenEpisodeGroupingChanged

    // MARK: - App Store Review Request

    case appStoreReviewRequested

    // MARK: - Signed out alert

    case signedOutAlertShown

    // MARK: - Discover

    case discoverShown
    case discoverCategoryShown
    case discoverFeaturedPodcastTapped
    case discoverFeaturedPodcastSubscribed
    case discoverShowAllTapped

    case discoverListImpression
    case discoverListShowAllTapped
    case discoverListEpisodeTapped
    case discoverListEpisodePlay
    case discoverListPodcastTapped
    case discoverListPodcastSubscribed

    case discoverFeaturedPageChanged
    case discoverSmallListPageChanged
    case discoverLargeListPageChanged
    case discoverNetworkListPageChanged

    case discoverRegionChanged
    case discoverCollectionLinkTapped

    // MARK: - Mini Player

    case miniPlayerLongPressMenuShown
    case miniPlayerLongPressMenuOptionTapped
    case miniPlayerLongPressMenuDismissed

    // MARK: - Up Next

    case upNextShown
    case upNextQueueCleared
    case upNextNowPlayingTapped
    case upNextQueueEpisodeTapped
    case upNextQueueEpisodeLongPressed
    case upNextMultiSelectEntered
    case upNextSelectAllButtonTapped
    case upNextMultiSelectExited
    case upNextQueueReordered
    case upNextDismissed

    // MARK: - Privacy

    case privacySettingsShown
    case analyticsOptIn
    case analyticsOptOut

    // MARK: - Player

    case playerShown
    case playerDismissed

    case playerTabSelected
    case playerShowNotesLinkTapped
    case playerChapterSelected

    case playerPreviousChapterTapped
    case playerNextChapterTapped

    // MARK: - Player: Sleep Timer

    case playerSleepTimerEnabled
    case playerSleepTimerExtended
    case playerSleepTimerCancelled

    // MARK: - Player: Shelf

    case playerShelfActionTapped
    case playerShelfOverflowMenuShown
    case playerShelfOverflowMenuRearrangeStarted
    case playerShelfOverflowMenuRearrangeActionMoved
    case playerShelfOverflowMenuRearrangeFinished

    // MARK: - Episode Events

    case episodeStarred
    case episodeBulkStarred

    case episodeUnstarred
    case episodeBulkUnstarred

    case episodeDownloadQueued
    case episodeDownloadFinished
    case episodeBulkDownloadQueued
    case episodeDownloadCancelled

    case episodeUploadQueued
    case episodeUploadFinished
    case episodeUploadCancelled
    case episodeDeletedFromCloud

    case episodeDownloadDeleted
    case episodeBulkDownloadDeleted

    case episodeArchived
    case episodeBulkArchived

    case episodeUnarchived
    case episodeBulkUnarchived

    case episodeMarkedAsPlayed
    case episodeBulkMarkedAsPlayed

    case episodeMarkedAsUnplayed
    case episodeBulkMarkedAsUnplayed

    case episodeAddedToUpNext
    case episodeBulkAddToUpNext

    case episodeRemovedFromUpNext

    case podcastShared

    // MARK: - Episode Detail

    case episodeDetailShown
    case episodeDetailShowNotesLinkTapped
    case episodeDetailPodcastNameTapped
    case episodeDetailDismissed

    // MARK: - Multi Select View

    case multiSelectViewOverflowMenuShown
    case multiSelectViewOverflowMenuRearrangeStarted
    case multiSelectViewOverflowMenuRearrangeActionMoved
    case multiSelectViewOverflowMenuRearrangeFinished

    // MARK: - Pull to Refresh

    case pulledToRefresh

    // MARK: - Push notifications

    case notificationsOptInShown
    case notificationsOptInAllowed
    case notificationsOptInDenied

    // MARK: - Podcast Settings

    case podcastSettingsFeedErrorTapped
    case podcastSettingsFeedErrorUpdateTapped
    case podcastSettingsFeedErrorFixSucceeded
    case podcastSettingsFeedErrorFixFailed

    case podcastSettingsAutoDownloadToggled
    case podcastSettingsNotificationsToggled
    case podcastSettingsAutoAddUpNextToggled
    case podcastSettingsAutoAddUpNextPositionOptionChanged

    case podcastSettingsCustomPlaybackEffectsToggled

    case podcastSettingsSkipFirstChanged
    case podcastSettingsSkipLastChanged

    case podcastSettingsAutoArchiveToggled
    case podcastSettingsAutoArchivePlayedChanged
    case podcastSettingsAutoArchiveInactiveChanged
    case podcastSettingsAutoArchiveEpisodeLimitChanged

    case podcastSettingsSiriShortcutAdded
    case podcastSettingsSiriShortcutRemoved

    // MARK: - Settings: Plus

    case settingsPlusShown
    case settingsPlusUpgradeButtonTapped
    case settingsPlusLearnMoreTapped

    // MARK: - Settings: General

    case settingsGeneralShown
    case settingsGeneralRowActionChanged
    case settingsGeneralEpisodeGroupingChanged
    case settingsGeneralArchivedEpisodesChanged
    case settingsGeneralUpNextSwipeChanged
    case settingsGeneralOpenLinksInBrowserToggled
    case settingsGeneralSkipForwardChanged
    case settingsGeneralSkipBackChanged
    case settingsGeneralKeepScreenAwakeToggled
    case settingsGeneralOpenPlayerAutomaticallyToggled
    case settingsGeneralIntelligentPlaybackToggled
    case settingsGeneralPlayUpNextOnTapToggled
    case settingsGeneralRemoteSkipsChaptersToggled
    case settingsGeneralExtraPlaybackActionsToggled
    case settingsGeneralLegacyBluetoothToggled
    case settingsGeneralMultiSelectGestureToggled
    case settingsGeneralPublishChapterTitlesToggled
    case settingsGeneralAutoplayToggled

    // MARK: - Settings: Notifications

    case settingsNotificationsShown
    case settingsNotificationsNewEpisodesToggled
    case settingsNotificationsPodcastsChanged
    case settingsNotificationsAppBadgeChanged

    // MARK: - Settings: Appearance

    case settingsAppearanceShown
    case settingsAppearanceFollowSystemThemeToggled
    case settingsAppearanceThemeChanged
    case settingsAppearanceLightThemeChanged
    case settingsAppearanceDarkThemeChanged
    case settingsAppearanceAppIconChanged
    case settingsAppearanceRefreshAllArtworkTapped
    case settingsAppearanceUseEmbeddedArtworkToggled

    // MARK: - Settings: Auto Archive

    case settingsAutoArchiveShown
    case settingsAutoArchivePlayedChanged
    case settingsAutoArchiveInactiveChanged
    case settingsAutoArchiveIncludeStarredToggled

    // MARK: - Settings: Auto Download

    case settingsAutoDownloadShown
    case settingsAutoDownloadUpNextToggled
    case settingsAutoDownloadNewEpisodesToggled
    case settingsAutoDownloadPodcastsChanged
    case settingsAutoDownloadFiltersChanged
    case settingsAutoDownloadOnlyOnWifiToggled

    // MARK: - Settings: Auto Add to Up Next

    case settingsAutoAddUpNextShown
    case settingsAutoAddUpNextAutoAddLimitChanged
    case settingsAutoAddUpNextLimitReachedChanged
    case settingsAutoAddUpNextPodcastsChanged
    case settingsAutoAddUpNextPodcastPositionOptionChanged

    // MARK: - Settings: Storage & Data Use

    case settingsStorageShown
    case settingsStorageWarnBeforeUsingDataToggled

    // MARK: - Settings: Siri Shortcuts

    case settingsSiriShown
    case settingsSiriShortcutAdded
    case settingsSiriShortcutRemoved

    // MARK: - Settings: Apple Watch

    case settingsAppleWatchShown
    case settingsAppleWatchAutoDownloadUpNextToggled
    case settingsAppleWatchAutoDownloadEpisodesChanged
    case settingsAppleWatchAutoDownloadDeleteDownloadsToggled

    // MARK: - Settings: Files

    case settingsFilesShown
    case settingsFilesAutoAddUpNextToggled
    case settingsFilesDeleteLocalFileAfterPlayingToggled
    case settingsFilesDeleteCloudFileAfterPlayingToggled
    case settingsFilesAutoUploadToCloudToggled
    case settingsFilesAutoDownloadFromCloudToggled
    case settingsFilesOnlyOnWifiToggled

    // MARK: - Settings: Help and Feedback

    case settingsHelpShown

    // MARK: - Settings: Import / Export OPML

    case settingsImportShown
    case settingsImportExportTapped
    case settingsImportExportStarted
    case settingsImportExportFinished
    case settingsImportExportFailed

    // MARK: - Settings: About

    case settingsAboutShown

    // MARK: - OPML Import

    case opmlImportStarted
    case opmlImportFailed
    case opmlImportFinished

    // MARK: - Subscribe / Unsubscribe

    case podcastSubscribed
    case podcastUnsubscribed

    // MARK: - Podcast Search

    case searchShown
    case searchDismissed
    case searchPerformed
    case searchFailed
    case searchResultTapped
    case searchListShown

    // MARK: - Chromecast

    case chromecastViewShown
    case chromecastStartedCasting
    case chromecastStoppedCasting
    case chromecastViewDismissed

    // MARK: - Podcast List Share

    case sharePodcastsShown
    case sharePodcastsPodcastsSelected
    case sharePodcastsListPublishStarted
    case sharePodcastsListPublishSucceeded
    case sharePodcastsListPublishFailed

    // MARK: - Incoming Share List

    case incomingShareListShown
    case incomingShareListSubscribedAll

    // MARK: - End of Year stats

    case endOfYearModalShown
    case endOfYearStoriesShown
    case endOfYearStoriesDismissed
    case endOfYearStoriesFailedToLoad
    case endOfYearStoryReplayButtonTapped
    case endOfYearStoryShown
    case endOfYearStoryShare
    case endOfYearStoryShared
    case endOfYearProfileCardTapped

    // MARK: - Welcome View

    case welcomeShown
    case welcomeImportTapped
    case welcomeDiscoverTapped
    case welcomeDismissed

    // MARK: - Import

    case onboardingImportShown
    case onboardingImportAppSelected
    case onboardingImportOpenAppTapped
    case onboardingImportDismissed

    // MARK: - Cancel
    case cancelConfirmationViewShown
    case cancelConfirmationViewDismissed
    case cancelConfirmationStayButtonTapped
    case cancelConfirmationCancelButtonTapped

    // MARK: - Search History
    case searchHistoryCleared
    case searchHistoryItemTapped
    case searchHistoryItemDeleteButtonTapped

    // MARK: - Ratings
    case ratingStarsTapped

    // MARK: - Patron
    case patronWelcomeAppIconChanged

}
