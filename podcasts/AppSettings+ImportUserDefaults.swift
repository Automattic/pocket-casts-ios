import PocketCastsServer
import PocketCastsUtils

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
        self.update(\.$gridOrder, value: Int32(ServerSettings.homeGridSortOrder()))
        self.update(\.$gridLayout, value: Int32(UserDefaults.standard.integer(forKey: Settings.podcastLibraryGridTypeKey)))
        self.update(\.$badges, value: Int32(UserDefaults.standard.integer(forKey: Settings.badgeKey)))
    }
}
