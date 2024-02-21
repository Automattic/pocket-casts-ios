import PocketCastsServer
import PocketCastsUtils
import PocketCastsDataModel

extension SettingsStore<AppSettings> {
    /// Updates the values in AppSettings with
    /// - Parameter userDefaults: The UserDefaults to read values from
    func importUserDefaults(_ userDefaults: UserDefaults = UserDefaults.standard) {
        self.update(\.$openLinks, value: userDefaults.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser))
        self.update(\.$rowAction, value: Int32(userDefaults.integer(forKey: Settings.primaryRowActionKey)))
        self.update(\.$skipForward, value: Int32(ServerSettings.skipForwardTime()))
        self.update(\.$skipBack, value: Int32(ServerSettings.skipBackTime()))
        self.update(\.$keepScreenAwake, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.keepScreenOnWhilePlaying))
        self.update(\.$openPlayer, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.openPlayerAutomatically))
        self.update(\.$intelligentResumption, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.intelligentPlaybackResumption))
        self.update(\.$episodeGrouping, value: Int32(UserDefaults.standard.integer(forKey: Settings.podcastGroupingDefaultKey)))
        self.update(\.$showArchived, value: UserDefaults.standard.bool(forKey: Settings.defaultArchiveBehaviour))
        self.update(\.$upNextSwipe, value: Int32(UserDefaults.standard.integer(forKey: Settings.primaryUpNextSwipeActionKey)))
        self.update(\.$playUpNextOnTap, value: UserDefaults.standard.bool(forKey: Settings.playUpNextOnTapKey))
        self.update(\.$playbackActions, value: UserDefaults.standard.bool(forKey: Settings.mediaSessionActionsKey))
        self.update(\.$legacyBluetooth, value: UserDefaults.standard.bool(forKey: Settings.legacyBtSupportKey))
        self.update(\.$multiSelectGesture, value: UserDefaults.standard.bool(forKey: Settings.multiSelectGestureKey))
        self.update(\.$chapterTitles, value: UserDefaults.standard.bool(forKey: Settings.publishChapterTitlesKey))
        self.update(\.$autoPlayEnabled, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.autoplay))
        self.update(\.$volumeBoost, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.globalVolumeBoost))
        self.update(\.$trimSilence, value: Int32(UserDefaults.standard.integer(forKey: Constants.UserDefaults.globalRemoveSilence)))
        self.update(\.$playbackSpeed, value: UserDefaults.standard.double(forKey: Constants.UserDefaults.globalPlaybackSpeed))
        self.update(\.$warnDataUsage, value: !UserDefaults.standard.bool(forKey: Settings.allowCellularDownloadKey))
        self.update(\.$playerBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.playerSort.value))
        self.update(\.$podcastBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.podcastSort.value))
        self.update(\.$episodeBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.episodeSort.value))
        self.update(\.$headphoneControlsNextAction, value: HeadphoneControl(action: Constants.UserDefaults.headphones.nextAction.unlockedValue))
        self.update(\.$headphoneControlsPreviousAction, value: HeadphoneControl(action: Constants.UserDefaults.headphones.previousAction.unlockedValue))
        self.update(\.$privacyAnalytics, value: !UserDefaults.standard.bool(forKey: Constants.UserDefaults.analyticsOptOut))
        self.update(\.$marketingOptIn, value: UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.marketingOptInKey))
        self.update(\.$freeGiftAcknowledgement, value: UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgement))
        if let time = AutoArchiveAfterTime(rawValue: UserDefaults.standard.double(forKey: Settings.autoArchivePlayedAfterKey)), let played = AutoArchiveAfterPlayed(time: time) {
            self.update(\.$autoArchivePlayed, value: played.rawValue)
        }
        if let time = AutoArchiveAfterTime(rawValue: UserDefaults.standard.double(forKey: Settings.autoArchiveInactiveAfterKey)), let inactive = AutoArchiveAfterInactive(time: time) {
            self.update(\.$autoArchiveInactive, value: inactive.rawValue)
        }
        self.update(\.$autoArchiveIncludesStarred, value: UserDefaults.standard.bool(forKey: Settings.archiveStarredEpisodesKey))
    }
}
