import Foundation

enum AnalyticsEvent: String {
    // MARK: - App Lifecycle

    case applicationInstalled
    case applicationOpened
    case applicationUpdated
    case applicationClosed

    case appClipOpened

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
    case plusPromotionNotNowButtonTapped
    case plusPromotionSubscriptionTierChanged
    case plusPromotionSubscriptionFrequencyChanged
    case plusPromotionPrivacyPolicyTapped
    case plusPromotionTermsAndConditionsTapped
    case plusPromotionDetailsTapped

    // MARK: - Setup Account

    case setupAccountShown
    case setupAccountDismissed
    case setupAccountButtonTapped

    // MARK: - Onboarding

    case onboardingCarouselShown
    case onboardingGetStarted

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
    case podcastsListDiscoverButtonTapped

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
    case profileBookmarksShow

    case accountDetailsCancelTapped
    case accountDetailsShowTOS
    case accountDetailsShowPrivacyPolicy
    case accountDetailsChangeAvatar

    // MARK: - Upgrade banner

    case upgradeBannerDismissed

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

    case suggestedFoldersPageShown
    case suggestedFoldersPageDismissed
    case suggestedFoldersUseSuggestedFoldersTapped
    case suggestedFoldersCreateCustomFolderTapped
    case suggestedFoldersPreviewFolderTapped
    case suggestedFoldersReplaceFoldersTapped
    case suggestedFoldersReplaceFoldersConfirmTapped

    // MARK: - Tab Bar Items

    case podcastsTabOpened
    case filtersTabOpened
    case discoverTabOpened
    case profileTabOpened
    case upNextTabOpened

    // MARK: - Downloads View

    case downloadsShown
    case downloadsOptionsButtonTapped
    case downloadsOptionsModalOptionTapped
    case freeUpSpaceBannerShown
    case freeUpSpaceManageDownloadsTapped
    case freeUpSpaceModalShown
    case freeUpSpaceMaybeLaterTapped

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
    case listeningHistoryClearConfirmationShown
    case listeningHistoryClearConfirmationDismissed

    case listeningHistoryDiscoverButtonTapped

    // MARK: - Uploaded Files

    case uploadedFilesShown
    case uploadedFilesOptionsButtonTapped
    case uploadedFilesOptionsModalOptionTapped
    case uploadedFilesAddButtonTapped

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
    case userFileEditShown
    case userFileEditDismissed
    case userFileEditSave
    case userFileDeleteShown
    case userFileDeleteDismissed

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

    case playbackEffectSettingsViewAppeared
    case playbackEffectSettingsChanged
    case playbackEffectSpeedChanged
    case playbackEffectTrimSilenceToggled
    case playbackEffectTrimSilenceAmountChanged
    case playbackEffectVolumeBoostToggled

    case playbackChapterSkipped

    // MARK: - Autoplay
    case playbackEpisodeAutoplayed
    case autoplayStarted
    case autoplayFinishedLastEpisode

    // MARK: - Filters

    case filterListShown
    case filterListEditButtonToggled
    case filterListReordered

    case filterCreateButtonTapped

    case filterDeleted
    case filterUpdated
    case filterCreated

    case filterShown
    case filterTooltipShown
    case filterTooltipClosed

    case filterMultiSelectEntered
    case filterSelectAllButtonTapped
    case filterSelectAllAbove
    case filterSelectAllBelow
    case filterMultiSelectExited

    case filterOptionsButtonTapped
    case filterOptionsModalOptionTapped
    case filterSortByChanged
    case filterEditDismissed

    case filterSiriShortcutsShown
    case filterSiriShortcutAdded
    case filterSiriShortcutRemoved

    case filterAutoDownloadUpdated
    case filterAutoDownloadLimitUpdated

    case episodeRecentlyPlayedSortOptionTooltipShown
    case episodeRecentlyPlayedSortOptionTooltipDismissed

    // MARK: - Podcast screen

    case podcastScreenShown
    case podcastScreenFolderTapped
    case podcastScreenSettingsTapped
    case podcastScreenFundingTapped
    case podcastScreenSubscribeTapped
    case podcastScreenUnsubscribeTapped
    case podcastScreenSearchPerformed
    case podcastScreenSearchCleared
    case podcastScreenOptionsTapped
    case podcastScreenToggleArchived
    case podcastScreenShareTapped
    case podcastScreenToggleSummary
    case podcastScreenPodcastDescriptionTapped
    case podcastsScreenSortOrderChanged
    case podcastsScreenEpisodeGroupingChanged
    case podcastsScreenTabTapped
    case podcastScreenPodcastDescriptionLinkTapped
    case podcastScreenNotificationsTapped
    case podcastScreenPodcastDetailsLinkTapped
    case podcastScreenCategoryTapped
    case podcastScreenYouMightLikeTapped
    case podcastScreenYouMightLikeSubscribed
    case podcastScreenSeasonOptionsTapped
    case podcastScreenSeasonOptionsSelectAllTapped
    case podcastScreenSeasonOptionsDownloadAllTapped
    case podcastScreenSeasonOptionsRemoveAllTapped
    case podcastScreenSeasonOptionsArchiveAllTapped
    case podcastScreenSeasonOptionsUnarchiveAllTapped

    // MARK: - App Store Review Request

    case appStoreReviewRequested
    case rateUsTapped

    // MARK: - Signed out alert

    case signedOutAlertShown

    // MARK: - Discover

    case discoverShown
    case discoverCategoryShown
    case discoverCategoriesPillTapped
    case discoverFeaturedPodcastTapped
    case discoverFeaturedPodcastSubscribed
    case discoverShowAllTapped
    case discoverCategoryCloseButtonTapped
    case discoverCategoriesPickerPick
    case discoverCategoriesPickerClosed
    case discoverCategoriesPickerShown

    case discoverListImpression
    case discoverListShowAllTapped
    case discoverListEpisodeTapped
    case discoverListEpisodePlay
    case discoverListPodcastTapped
    case discoverListPodcastSubscribed
    case discoverListShareTapped

    case discoverFeaturedPageChanged
    case discoverSmallListPageChanged
    case discoverLargeListPageChanged
    case discoverNetworkListPageChanged

    case discoverRegionChanged
    case discoverCollectionLinkTapped

    case discoverAdCategoryTapped
    case discoverAdCategorySubscribed

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
    case upNextShuffleEnabled
    case upNextDiscoverButtonTapped

    // MARK: - Privacy

    case privacySettingsShown
    case analyticsOptIn
    case analyticsOptOut
    case analyticsThirdPartyOptIn
    case analyticsThirdPartyOptOut

    // MARK: - Player

    case playerShown
    case playerDismissed

    case playerTabSelected
    case playerShowNotesLinkTapped
    case playerChapterSelected
    case playerPodcastNameTapped

    case playerPreviousChapterTapped
    case playerNextChapterTapped

    // MARK: - Player: Sleep Timer

    case playerSleepTimerEnabled
    case playerSleepTimerExtended
    case playerSleepTimerCancelled
    case playerSleepTimerRestarted
    case playerSleepTimerSettingsTapped

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
    case episodeDownloadFailed
    case episodeDownloadsStale
    case episodeDownloadTasks

    case episodeUploadQueued
    case episodeUploadFinished
    case episodeUploadFailed
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

    case episodeRemovedListeningHistory

    case podcastShared

    // MARK: - Episode Detail

    case episodeDetailShown
    case episodeDetailShowNotesLinkTapped
    case episodeDetailPodcastNameTapped
    case episodeDetailDismissed
    case episodeDetailTabChanged

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

    case notificationsPermissionsShown
    case notificationsPermissionsAllowTapped
    case notificationsPermissionsNotNowTapped
    case notificationsPermissionsOpenSystemSettings

    case notificationOpened

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
    case settingsGeneralEpisodeGroupingApplyToExisting
    case settingsGeneralEpisodeGroupingDoNotApplyToExisting
    case settingsGeneralArchivedEpisodesChanged
    case settingsGeneralArchivedEpisodesApplyToExisting
    case settingsGeneralArchivedEpisodesDoNotApplyToExisting
    case settingsGeneralUpNextSwipeChanged
    case settingsGeneralOpenLinksInBrowserToggled
    case settingsGeneralSkipForwardChanged
    case settingsGeneralSkipBackChanged
    case settingsGeneralKeepScreenAwakeToggled
    case settingsGeneralOpenPlayerAutomaticallyToggled
    case settingsGeneralDisableLockScreenScrubberToggled
    case settingsGeneralIntelligentPlaybackToggled
    case settingsGeneralPlayUpNextOnTapToggled
    case settingsGeneralRemoteSkipsChaptersToggled
    case settingsGeneralExtraPlaybackActionsToggled
    case settingsGeneralLegacyBluetoothToggled
    case settingsGeneralMultiSelectGestureToggled
    case settingsGeneralPublishChapterTitlesToggled
    case settingsGeneralAutoplayToggled
    case settingsGeneralAutoSleepTimerRestartToggled
    case settingsGeneralShakeToResetSleepTimerToggled

    // MARK: - Settings: Notifications

    case settingsNotificationsShown
    case settingsNotificationsNewEpisodesToggled
    case settingsNotificationsPodcastsChanged
    case settingsNotificationsAppBadgeChanged
    case settingsNotificationsTrendingToggle
    case settingsNotificationsDailyRemindersToggle
    case settingsNotificationsNewFeaturesToggle
    case settingsNotificationsOffersToggle

    // MARK: - Settings: Appearance

    case settingsAppearanceShown
    case settingsAppearanceFollowSystemThemeToggled
    case settingsAppearanceThemeChanged
    case settingsAppearanceLightThemeChanged
    case settingsAppearanceDarkThemeChanged
    case settingsAppearanceAppIconChanged
    case settingsAppearanceRefreshAllArtworkTapped
    case settingsAppearanceUseEmbeddedArtworkToggled
    case settingsAppearanceUseDarkUpNextToggled

    // MARK: - Settings: Auto Archive

    case settingsAutoArchiveShown
    case settingsAutoArchivePlayedChanged
    case settingsAutoArchiveInactiveChanged
    case settingsAutoArchiveIncludeStarredToggled

    // MARK: - Settings: Auto Download

    case settingsAutoDownloadShown
    case settingsAutoDownloadUpNextToggled
    case settingsAutoDownloadNewEpisodesToggled
    case settingsAutoDownloadOnFollowPodcastToggled
    case settingsAutoDownloadLimitDownloadsChanged
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
    case settingsGetSupport
    case settingsLeaveFeedback
    case exportDatabaseTapped

    // MARK: - Settings: Import / Export OPML

    case settingsImportShown
    case settingsImportExportTapped
    case settingsImportExportStarted
    case settingsImportExportFinished
    case settingsImportExportFailed

    // MARK: - Settings: About

    case settingsAboutShown
    case settingsAboutShareWithFriendsTapped
    case settingsAboutWebsiteTapped
    case settingsAboutInstagramTapped
    case settingsAboutTwitterTapped
    case settingsAboutAutomatticFamilyTapped
    case settingsAboutLegalAndMoreTapped
    case settingsAboutWorkWithUsTapped

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
    case searchPredictiveFailed
    case searchResultTapped
    case searchListShown
    case searchCleared
    case searchFilterTapped
    case searchPredictiveShown
    case searchPredictiveTermTapped

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
    case endOfYearUpsellShown
    case endOfYearLearnRatingsShown

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

    // MARK: - Recommendations

    case recommendationsShown
    case recommendationsDismissed
    case recommendationsSearchTapped
    case recommendationsMoreTapped
    case recommendationsContinueTapped
    case recommendationsImportTapped

    // MARK: - Interests
    case onboardingInterestsShown
    case onboardingInterestsNotNowTapped
    case onboardingInterestsCategorySelected
    case onboardingInterestsShownMoreTapped
    case onboardingInterestsContinueTapped

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
    case ratingScreenShown
    case ratingScreenDismissed
    case ratingScreenSubmitTapped
    case notAllowedToRateScreenShown
    case notAllowedToRateScreenDismissed

    // MARK: - Patron
    case patronWelcomeAppIconChanged

    // MARK: - What's New
    case whatsnewShown
    case whatsnewDismissed
    case whatsnewConfirmButtonTapped

    // MARK: - Bookmarks
    case bookmarkCreated
    case bookmarkUpdateTitle
    case bookmarksGetBookmarksButtonTapped
    case bookmarksEmptyGoToHeadphoneSettings
    case bookmarkPlayTapped
    case bookmarksSortByChanged
    case bookmarkDeleted
    case bookmarkShareTapped
    case bookmarkEditFormShown
    case bookmarkEditFormDismissed
    case bookmarkEditFormSubmitted
    case bookmarkDeleteFormShown
    case bookmarkDeleteFormDismissed
    case bookmarkDeleteFormSubmitted

    // MARK: - Headphone Controls
    case settingsHeadphoneControlsShown
    case settingsHeadphoneControlsNextChanged
    case settingsHeadphoneControlsPreviousChanged
    case settingsHeadphoneControlsBookmarkSoundToggled

    // MARK: - Skipping Chapters
    case deselectChaptersToggledOn
    case deselectChaptersToggledOff
    case deselectChaptersChapterSelected
    case deselectChaptersChapterDeselected

    // MARK: - Kids Profile
    case kidsProfileBannerSeen
    case kidsProfileEarlyAccessRequested
    case kidsProfileBannerDismissed
    case kidsProfileSendFeedbackTapped
    case kidsProfileNoThankYouTapped
    case kidsProfileThankYouForYourInterestSeen
    case kidsProfileFeedbackFormSeen
    case kidsProfileFeedbackSent

    // MARK: - Transcript

    case transcriptShown
    case transcriptError
    case transcriptDismissed
    case transcriptSearchShown
    case transcriptSearchNextResult
    case transcriptSearchPreviousResult
    case transcriptGeneratedPaywallShown
    case transcriptGeneratedPaywallDismissed
    case transcriptGeneratedPaywallSubscribeTapped
    case episodeDetailTranscriptCardShown
    case episodeDetailTranscriptCardTapped
    case episodeTranscriptShown
    case transcriptShared

    // MARK: - Widgets

    case widgetInstalled
    case widgetUninstalled
    case widgetInteraction

    // MARK: - Share Screen
    case shareScreenShown
    case shareScreenPlayTapped
    case shareScreenPauseTapped
    case shareScreenClipShared
    case shareScreenNavigationButtonTapped
    case shareScreenEditButtonTapped
    case shareScreenCloseButtonTapped

    // MARK: - Referrals

    case referralTooltipShow
    case referralTooltipTapped
    case referralShareScreenShown
    case referralShareScreenDismissed
    case referralPassShared
    case referralClaimScreenShown
    case referralActivateTapped
    case referralNotNowTapped
    case referralUsedScreenShown
    case referralPassBannerShown
    case referralPurchaseShown
    case referralPurchaseSuccess
    case referralPassBannerHideTapped

    // MARK: - Winback
    case winbackScreenShown
    case winbackScreenDismissed
    case winbackContinueButtonTap
    case winbackMainScreenRowTap
    case winbackOfferClaimedDoneButtonTapped
    case winbackAvailablePlansBackButtonTapped
    case winbackCancelConfirmationStayButtonTapped
    case winbackCancelConfirmationCancelButtonTapped
    case winbackAvailablePlansSelectPlan
    case winbackAvailablePlansNewPlanPurchaseSuccessful
    case winbackWinbackOfferCancelButtonTapped

    // MARK: - Cancel Subscription Survey
    case cancelSubscriptionSurveyShown
    case cancelSubscriptionSurveyDismissed
    case cancelSubscriptionSurveySubmitButtonTapped
    case cancelSubscriptionSurveyFeedbackSubmitSuccess
    case cancelSubscriptionSurveyFeedbackSubmitError

    // MARK: - Champion Dialog
    case pocketCastsChampionDialogShown
    case pocketCastsChampionDialogRateButtonTapped

    // MARK: - User Satisfaction Survey
    case userSatisfactionSurveyShown
    case userSatisfactionSurveyDismissed
    case userSatisfactionSurveyYesResponse
    case userSatisfactionSurveyNoResponse

    // MARK: - Select/Choose Podcasts
    case settingsSelectPodcastsShown
    case settingsSelectPodcastsDismissed
    case settingsSelectPodcastsSelectAllTapped
    case settingsSelectPodcastsSelectNoneTapped
    case settingsSelectPodcastsPodcastToggled
    case settingsSelectPodcastsSelectAllPodcastsToggled

    // MARK: - Podcast Feed Reload
    case podcastScreenRefreshEpisodeList
    case podcastScreenRefreshNoEpisodesFound
    case podcastScreenRefreshNewEpisodeFound
    case podcastRefreshEpisodeTooltipShown
    case podcastRefreshEpisodeTooltipDismissed

    // MARK: - Encourage Account Creation
    case informationalModalViewShowed
    case informationalModalViewDismissed
    case informationalModalViewGetStartedTap
    case informationalModalViewLoginTap
    case informationalModalViewCardShowed
    case informationalBannerViewDismissed
    case informationalBannerViewCreateAccountTap

    // MARK: - Podroll Information Modal
    case podcastScreenPodrollInformationModelShown
    case podcastScreenPodrollPodcastSubscribed
    case podcastScreenPodrollPodcastTapped

    // MARK: - Banner Ads
    case bannerAdImpression
    case bannerAdTapped
    case bannerAdReport
}
