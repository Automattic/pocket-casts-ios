import PocketCastsServer
import PocketCastsUtils
import PocketCastsDataModel

extension SettingsStore<AppSettings> {
    /// Updates the values in AppSettings with
    /// - Parameter userDefaults: The UserDefaults to read values from
    func importUserDefaults(_ userDefaults: UserDefaults = UserDefaults.standard) {
        let date = Date.syncDefaultDate
        self.update(\.$openLinks, value: userDefaults.bool(forKey: Constants.UserDefaults.openLinksInExternalBrowser), modifiedAt: date)
        self.update(\.$rowAction, value: Int32(userDefaults.integer(forKey: Settings.primaryRowActionKey)), modifiedAt: date)
        self.update(\.$skipForward, value: Int32(ServerSettings.skipForwardTime()), modifiedAt: date)
        self.update(\.$skipBack, value: Int32(ServerSettings.skipBackTime()), modifiedAt: date)
        self.update(\.$keepScreenAwake, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.keepScreenOnWhilePlaying), modifiedAt: date)
        self.update(\.$openPlayer, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.openPlayerAutomatically), modifiedAt: date)
        self.update(\.$intelligentResumption, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.intelligentPlaybackResumption), modifiedAt: date)
        self.update(\.$episodeGrouping, value: Int32(UserDefaults.standard.integer(forKey: Settings.podcastGroupingDefaultKey)), modifiedAt: date)
        self.update(\.$showArchived, value: UserDefaults.standard.bool(forKey: Settings.defaultArchiveBehaviour), modifiedAt: date)
        self.update(\.$upNextSwipe, value: Int32(UserDefaults.standard.integer(forKey: Settings.primaryUpNextSwipeActionKey)), modifiedAt: date)
        self.update(\.$playUpNextOnTap, value: UserDefaults.standard.bool(forKey: Settings.playUpNextOnTapKey), modifiedAt: date)
        self.update(\.$playbackActions, value: UserDefaults.standard.bool(forKey: Settings.mediaSessionActionsKey), modifiedAt: date)
        self.update(\.$legacyBluetooth, value: UserDefaults.standard.bool(forKey: Settings.legacyBtSupportKey), modifiedAt: date)
        self.update(\.$multiSelectGesture, value: UserDefaults.standard.bool(forKey: Settings.multiSelectGestureKey), modifiedAt: date)
        self.update(\.$chapterTitles, value: UserDefaults.standard.bool(forKey: Settings.publishChapterTitlesKey), modifiedAt: date)
        self.update(\.$autoPlayEnabled, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.autoplay), modifiedAt: date)
        self.update(\.$notifications, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.pushEnabled), modifiedAt: date)
        self.update(\.$appBadge, value: Int32(UserDefaults.standard.integer(forKey: Constants.UserDefaults.appBadge)), modifiedAt: date)
        if let filter = UserDefaults.standard.string(forKey: Constants.UserDefaults.appBadgeFilterUuid) {
            self.update(\.$appBadgeFilter, value: filter, modifiedAt: date)
        }
        self.update(\.$volumeBoost, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.globalVolumeBoost))
        if let trimSilenceAmount = TrimSilenceAmount(rawValue: Int32(UserDefaults.standard.integer(forKey: Constants.UserDefaults.globalRemoveSilence))) {
            self.update(\.$trimSilence, value: TrimSilence(amount: trimSilenceAmount).rawValue, modifiedAt: date)
        }
        self.update(\.$playbackSpeed, value: UserDefaults.standard.double(forKey: Constants.UserDefaults.globalPlaybackSpeed), modifiedAt: date)
        self.update(\.$warnDataUsage, value: !UserDefaults.standard.bool(forKey: Settings.allowCellularDownloadKey), modifiedAt: date)
        self.update(\.$playerBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.playerSort.value), modifiedAt: date)
        self.update(\.$podcastBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.podcastSort.value), modifiedAt: date)
        self.update(\.$episodeBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.episodeSort.value), modifiedAt: date)
        self.update(\.$profileBookmarksSortType, value: BookmarksSort(option: Constants.UserDefaults.bookmarks.profileSort.value), modifiedAt: date)
        self.update(\.$headphoneControlsNextAction, value: HeadphoneControl(action: Constants.UserDefaults.headphones.nextAction.unlockedValue), modifiedAt: date)
        self.update(\.$headphoneControlsPreviousAction, value: HeadphoneControl(action: Constants.UserDefaults.headphones.previousAction.unlockedValue), modifiedAt: date)
        self.update(\.$privacyAnalytics, value: !UserDefaults.standard.bool(forKey: Constants.UserDefaults.analyticsOptOut), modifiedAt: date)
        self.update(\.$marketingOptIn, value: UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.marketingOptInKey), modifiedAt: date)
        self.update(\.$freeGiftAcknowledgement, value: UserDefaults.standard.bool(forKey: ServerConstants.UserDefaults.subscriptionGiftAcknowledgement), modifiedAt: date)
        if let time = AutoArchiveAfterTime(rawValue: UserDefaults.standard.double(forKey: Settings.autoArchivePlayedAfterKey)), let played = AutoArchiveAfterPlayed(time: time) {
            self.update(\.$autoArchivePlayed, value: played.rawValue, modifiedAt: date)
        }
        if let time = AutoArchiveAfterTime(rawValue: UserDefaults.standard.double(forKey: Settings.autoArchiveInactiveAfterKey)), let inactive = AutoArchiveAfterInactive(time: time) {
            self.update(\.$autoArchiveInactive, value: inactive.rawValue, modifiedAt: date)
        }
        self.update(\.$autoArchiveIncludesStarred, value: UserDefaults.standard.bool(forKey: Settings.archiveStarredEpisodesKey))
        if let lastPlaylist = AutoplayHelper().userDefaultsPlaylist {
            self.update(\.$autoPlayLastListUuid, value: AutoPlaySource(playlist: lastPlaylist), modifiedAt: date)
		}
        if let old = LibrarySort.Old(rawValue: ServerSettings.homeGridSortOrder()) {
            self.update(\.$gridOrder, value: LibrarySort(old: old), modifiedAt: date)
        }
        if let old = LibraryType.Old(rawValue: UserDefaults.standard.integer(forKey: Settings.podcastLibraryGridTypeKey)) {
            self.update(\.$gridLayout, value: LibraryType(old: old), modifiedAt: date)
        }
        self.update(\.$badges, value: Int32(UserDefaults.standard.integer(forKey: Settings.badgeKey)), modifiedAt: date)
        self.update(\.$filesAutoUpNext, value: UserDefaults.standard.bool(forKey: Settings.userEpisodeAutoAddToUpNextKey), modifiedAt: date)
        self.update(\.$filesAfterPlayingDeleteLocal, value: UserDefaults.standard.bool(forKey: Settings.userEpisodeRemoveFileAfterPlayingKey), modifiedAt: date)
        self.update(\.$filesAfterPlayingDeleteCloud, value: UserDefaults.standard.bool(forKey: Settings.userEpisodeRemoveFromCloudAfterPlayingKey), modifiedAt: date)
        self.update(\.$playerShelf, value: (UserDefaults.standard.playerActions ?? PlayerAction.defaultActions).map { ActionOption.known($0) }, modifiedAt: date)
        self.update(\.$useEmbeddedArtwork, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.loadEmbeddedImages), modifiedAt: date)
        if let oldTheme = ThemeType.Old(rawValue: UserDefaults.standard.integer(forKey: Theme.themeKey)) {
            self.update(\.$theme, value: ThemeType(old: oldTheme), modifiedAt: date)
        }
        self.update(\.$useSystemTheme, value: UserDefaults.standard.bool(forKey: Constants.UserDefaults.shouldFollowSystemThemeKey), modifiedAt: date)
        if let oldTheme = ThemeType.Old(rawValue: UserDefaults.standard.integer(forKey: Theme.preferredLightThemeKey)) {
            self.update(\.$lightThemePreference, value: ThemeType(old: oldTheme), modifiedAt: date)
        }
        if let oldTheme = ThemeType.Old(rawValue: UserDefaults.standard.integer(forKey: Theme.preferredDarkThemeKey)) {
            self.update(\.$darkThemePreference, value: ThemeType(old: oldTheme), modifiedAt: date)
        }
        self.update(\.$useDarkUpNextTheme, value: Constants.UserDefaults.appearance.darkUpNextTheme.value, modifiedAt: date)
        self.update(\.$autoUpNextLimit, value: Int32(UserDefaults.standard.integer(forKey: ServerSettings.autoAddLimitKey)), modifiedAt: date)
        self.update(\.$autoUpNextLimitReached, value: Int32(UserDefaults.standard.integer(forKey: ServerSettings.onAutoAddLimitReachedKey)), modifiedAt: date)
        if let old = UploadedSort.Old(rawValue: UserDefaults.standard.integer(forKey: Settings.userEpisodeSortByKey)) {
            self.update(\.$filesSortOrder, value: UploadedSort(old: old), modifiedAt: date)
         }
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
