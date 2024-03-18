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
        self.update(\.$notifications, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.pushEnabled))
        self.update(\.$volumeBoost, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.globalVolumeBoost))
        if let trimSilenceAmount = TrimSilenceAmount(rawValue: Int32(UserDefaults.standard.integer(forKey: Constants.UserDefaults.globalRemoveSilence))) {
            self.update(\.$trimSilence, value: TrimSilence(amount: trimSilenceAmount).rawValue)
        }
        self.update(\.$playbackSpeed, value: UserDefaults.standard.double(forKey: Constants.UserDefaults.globalPlaybackSpeed))
        self.update(\.$warnDataUsage, value: !UserDefaults.standard.bool(forKey: Settings.allowCellularDownloadKey))
        self.update(\.$playerBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.playerSort.value))
        self.update(\.$podcastBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.podcastSort.value))
        self.update(\.$episodeBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.episodeSort.value))
        self.update(\.$profileBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.profileSort.value))
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
        self.update(\.$gridOrder, value: Int32(ServerSettings.homeGridSortOrder()))
        self.update(\.$gridLayout, value: Int32(UserDefaults.standard.integer(forKey: Settings.podcastLibraryGridTypeKey)))
        self.update(\.$badges, value: Int32(UserDefaults.standard.integer(forKey: Settings.badgeKey)))
        self.update(\.$filesAutoUpNext, value: UserDefaults.standard.bool(forKey: Settings.userEpisodeAutoAddToUpNextKey))
        self.update(\.$filesAfterPlayingDeleteLocal, value: UserDefaults.standard.bool(forKey: Settings.userEpisodeRemoveFileAfterPlayingKey))
        self.update(\.$filesAfterPlayingDeleteCloud, value: UserDefaults.standard.bool(forKey: Settings.userEpisodeRemoveFromCloudAfterPlayingKey))
        self.update(\.$playerShelf, value: (UserDefaults.standard.playerActions ?? PlayerAction.defaultActions).map { ActionOption.known($0) })
        self.update(\.$useEmbeddedArtwork, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.loadEmbeddedImages))
        if let oldTheme = ThemeType.Old(rawValue: UserDefaults.standard.integer(forKey: Theme.themeKey)) {
            self.update(\.$theme, value: ThemeType(old: oldTheme))
        }
        self.update(\.$useSystemTheme, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey))
        if let oldTheme = ThemeType.Old(rawValue: UserDefaults.standard.integer(forKey: Theme.preferredLightThemeKey)) {
            self.update(\.$lightThemePreference, value: ThemeType(old: oldTheme))
        }
        if let oldTheme = ThemeType.Old(rawValue: UserDefaults.standard.integer(forKey: Theme.preferredDarkThemeKey)) {
            self.update(\.$darkThemePreference, value: ThemeType(old: oldTheme))
        }
        self.update(\.$useDarkUpNextTheme, value: Constants.UserDefaults.appearance.darkUpNextTheme.value)
        self.update(\.$autoUpNextLimit, value: Int32(ServerSettings.autoAddToUpNextLimit()))
        self.update(\.$autoUpNextLimitReached, value: ServerSettings.onAutoAddLimitReached())
        importValue(\.$autoDownloadUpNext, forKey: Settings.autoDownloadUpNext, from: userDefaults)
        importValue(\.$autoDownloadUnmeteredOnly, forKey: Settings.allowCellularAutoDownloadKey, from: userDefaults)
        importValue(\.$cloudAutoDownload, forKey: ServerSettings.userEpisodeAutoDownloadKey, from: userDefaults)
        importValue(\.$cloudDownloadUnmeteredOnly, forKey: ServerSettings.userEpisodeOnlyOnWifiKey, from: userDefaults)
        importValue(\.$cloudAutoUpload, forKey: Settings.userEpisodeAutoUploadKey, from: userDefaults)
    }

    /// Imports a value of a given key from UserDefaults, only if that value exists
    /// - Parameters:
    ///   - modifiedKeyPath: The SettingsStore keyPath to update
    ///   - key: The key to check UserDefaults for
    ///   - from: The UserDefaults instance to check
    func importValue<T: Equatable & Codable>(_ modifiedKeyPath: WritableKeyPath<Value, ModifiedDate<T>>, forKey key: String, from: UserDefaults) {
        if let value = UserDefaults.standard.value(forKey: key) as? T {
            self.update(modifiedKeyPath, value: value)
        }
    }
}
