import XCTest
@testable import podcasts
@testable import PocketCastsServer
import PocketCastsDataModel
import PocketCastsUtils

final class SettingsTests: XCTestCase {

    private let userDefaultsSuiteName = "PocketCasts-SettingsTests"

    private var overriddenFlags = [FeatureFlag: Bool]()

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    private func override(flag: FeatureFlag, value: Bool) throws {
        overriddenFlags[flag] = flag.enabled
        try FeatureFlagOverrideStore().override(flag, withValue: value)
    }

    private func reset(flag: FeatureFlag) throws {
        if let oldValue = overriddenFlags[flag] {
            try FeatureFlagOverrideStore().override(flag, withValue: oldValue)
        }
    }

    private func setupSettingsStore() throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
    }

    func testImportOldHeadphoneControls() throws {
        try override(flag: .newSettingsStorage, value: false)
        try setupSettingsStore()

        let newNextAction = HeadphoneControlAction.nextChapter
        let newPreviousAction = HeadphoneControlAction.previousChapter

        Settings.headphonesNextAction = newNextAction
        Settings.headphonesPreviousAction = newPreviousAction

        try FeatureFlagOverrideStore().override(FeatureFlag.newSettingsStorage, withValue: true)

        SettingsStore.appSettings.importUserDefaults()

        XCTAssertEqual(newNextAction, Settings.headphonesNextAction, "Next action should be imported from old defaults")
        XCTAssertEqual(newPreviousAction, Settings.headphonesPreviousAction, "Previous action should be imported from old defaults")
        try reset(flag: .newSettingsStorage)
    }

    func testPlayerActions() throws {
        let unknownString = "test"
        try override(flag: .newSettingsStorage, value: true)
        try setupSettingsStore()
        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable }) // Set defaults

        SettingsStore.appSettings.playerShelf = [.known(.markPlayed), .unknown(unknownString)]
        Settings.updatePlayerActions([.addBookmark, .markPlayed])

        XCTAssertEqual([.addBookmark,
                        .markPlayed,
                        .effects,
                        .sleepTimer,
                        .routePicker,
                        .starEpisode,
                        .shareEpisode,
                        .goToPodcast,
                        .chromecast,
                        .archive], Settings.playerActions(), "Player actions should exclude unknown actions and include defaults")
        XCTAssertEqual([.known(.addBookmark), .known(.markPlayed), .unknown(unknownString)], SettingsStore.appSettings.playerShelf, "Player shelf should include unknowns at end")

        try reset(flag: .newSettingsStorage)
    }

    func testOldPlayerActions() throws {
        try override(flag: .newSettingsStorage, value: false)

        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable }) // Set defaults
        Settings.updatePlayerActions([.addBookmark, .markPlayed])

        XCTAssertEqual([.addBookmark,
                        .markPlayed,
                        .effects,
                        .sleepTimer,
                        .routePicker,
                        .starEpisode,
                        .shareEpisode,
                        .goToPodcast,
                        .chromecast,
                        .archive], Settings.playerActions(), "Player actions should include changes from update")

        try reset(flag: .newSettingsStorage)
    }

    func testImportOldPlayerActions() throws {
        // Start with disabled settingsSync
        try override(flag: .newSettingsStorage, value: false)

        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable })
        Settings.updatePlayerActions([.addBookmark, .markPlayed]) // This update is tested in testOldPlayerActions

        // Enable settingsSync to flip `Settings` to use the new value
        try FeatureFlagOverrideStore().override(FeatureFlag.newSettingsStorage, withValue: true)

        try setupSettingsStore()
        SettingsStore.appSettings.importUserDefaults()

        XCTAssertEqual([.addBookmark,
                        .markPlayed,
                        .effects,
                        .sleepTimer,
                        .routePicker,
                        .starEpisode,
                        .shareEpisode,
                        .goToPodcast,
                        .chromecast,
                        .archive], Settings.playerActions(), "Player actions should include changes from update")

        try reset(flag: .newSettingsStorage)
    }

    func testImportOldDefaults() throws {
        // Start with disabled settingsSync
        try override(flag: .newSettingsStorage, value: false)

        let newRowAction = PrimaryRowAction.stream
        let newSwipeAction = PrimaryUpNextSwipeAction.playLast
        let newAppBadge = AppBadge.newSinceLastOpened
        let newPlayedAfter = AutoArchiveAfterTime.after1Week
        let newInactiveAfter = AutoArchiveAfterTime.after90Days
        let newEpisodeSortBy = UploadedSort.titleAtoZ
        let newPlayerBookmarksSort = BookmarkSortOption.podcastAndEpisode
        let newEpisodeBookmarksSort = BookmarkSortOption.episode
        let newProfileBookmarksSort = BookmarkSortOption.newestToOldest
        let newHeadphonesNextAction = HeadphoneControlAction.previousChapter
        let newHeadphonesPreviousAction = HeadphoneControlAction.skipForward
        let newHomeFolderSortOrder = LibrarySort.titleAtoZ
        let newPodcastBadgeType = BadgeType.latestEpisode
        let newAutoPlayPlaylist = AutoplayHelper.Playlist.podcast(uuid: "1234")
        let newTheme = ThemeType.contrastLight
        let newPreferredLightTheme = ThemeType.contrastLight
        let newPreferredDarkTheme = ThemeType.contrastDark

        let newOpenLinks = true
        let newShowArchived = true
        let newSkipForward = 20
        let newSkipBack = 30
        let newKeepScreenAwake = true
        let newOpenPlayer = true
        let newIntelligentResumption = true
        let newPlayupNextOnTap = true
        let newPlaybackActions = true
        let newLegacyBluetooth = true
        let newMultiselectGesture = true
        let newChapterTitles = true
        let newAutoplayEnabled = true
        let newNotifications = true
        let newAppBadgeFilter = "1234"
        let newAutoarchiveIncludesStarred = true
        let newVolumeBoost = true
        let newTrimSilence = TrimSilence.medium
        let newPlaybackSpeed = 2.0
        let newFilesAutoUpNext = true
        let newFilesAfterPlayingDeleteLocal = true
        let newFilesAfterPlayingDeleteCloud = true
        let newWarnDataUsage = true
        let newAutoUpNextLimit = 3
        let newAutoUpNextLimitReached = AutoAddLimitReachedAction.addToTopOnly
        let newPrivacyAnalytics = true
        let newMarketingOptIn = true
        let newFreeGiftAcknowledgement = true
        let newGridOrder = LibrarySort.titleAtoZ
        let newGridLayout = LibraryType.fourByFour
        let newPlayerShelf: [PlayerAction] = [.effects, .markPlayed]
        let newUseSystemTheme = true
        let newUseEmbeddedArtwork = true
        let newUseDarkUpNextTheme = true

        Settings.setPrimaryRowAction(newRowAction)
        Settings.setPrimaryUpNextSwipeAction(newSwipeAction)
        Settings.appBadge = newAppBadge
        Settings.setAutoArchivePlayedAfter(newPlayedAfter.rawValue)
        Settings.setAutoArchiveInactiveAfter(newInactiveAfter.rawValue)
        Settings.setUserEpisodeSortBy(newEpisodeSortBy.rawValue)
        Settings.playerBookmarksSort.wrappedValue = newPlayerBookmarksSort
        Settings.episodeBookmarksSort.wrappedValue = newEpisodeBookmarksSort
        Settings.profileBookmarksSort.wrappedValue = newProfileBookmarksSort
        Settings.headphonesNextAction = newHeadphonesNextAction
        Settings.headphonesPreviousAction = newHeadphonesPreviousAction
        Settings.setHomeFolderSortOrder(order: newHomeFolderSortOrder)
        Settings.setPodcastBadgeType(newPodcastBadgeType)
        Settings.openLinks = newOpenLinks
        Settings.setShowArchivedDefault(newShowArchived)
        Settings.skipForwardTime = newSkipForward
        Settings.skipBackTime = newSkipBack
        Settings.keepScreenAwake = newKeepScreenAwake
        Settings.openPlayerAutomatically = newOpenPlayer
        Settings.intelligentResumption = newIntelligentResumption
        Settings.setPlayUpNextOnTap(newPlayupNextOnTap)
        Settings.setExtraMediaSessionActionsEnabled(newPlaybackActions)
        Settings.setLegacyBluetoothModeEnabled(newLegacyBluetooth)
        Settings.setMultiSelectGestureEnabled(newMultiselectGesture)
        Settings.setPublishChapterTitlesEnabled(newChapterTitles)
        Settings.autoplay = newAutoplayEnabled
        UserDefaults.standard.set(newNotifications, forKey: Constants.UserDefaults.pushEnabled)
        Settings.appBadgeFilterUuid = newAppBadgeFilter
        Settings.setArchiveStarredEpisodes(newAutoarchiveIncludesStarred)
        UserDefaults.standard.set(newVolumeBoost, forKey: Constants.UserDefaults.globalVolumeBoost)
        UserDefaults.standard.set(newTrimSilence.amount.rawValue, forKey: Constants.UserDefaults.globalRemoveSilence)
        UserDefaults.standard.set(newPlaybackSpeed, forKey: Constants.UserDefaults.globalPlaybackSpeed)
        Settings.setUserEpisodeAutoAddToUpNext(newFilesAutoUpNext)
        Settings.setUserEpisodeRemoveFileAfterPlaying(newFilesAfterPlayingDeleteLocal)
        Settings.setUserEpisodeRemoveFileAfterPlaying(newFilesAfterPlayingDeleteCloud)
        Settings.setMobileDataAllowed(!newWarnDataUsage)
        ServerSettings.setAutoAddToUpNextLimit(newAutoUpNextLimit)
        ServerSettings.setOnAutoAddLimitReached(action: newAutoUpNextLimitReached)
        Settings.setAnalytics(optOut: newPrivacyAnalytics)
        ServerSettings.setMarketingOptIn(newMarketingOptIn)
        Settings.setSubscriptionCancelledAcknowledged(newFreeGiftAcknowledgement)
        Settings.setHomeFolderSortOrder(order: newGridOrder)
        Settings.setLibraryType(newGridLayout)
        Settings.setUserEpisodeSortBy(newEpisodeSortBy.rawValue)
        Settings.updatePlayerActions(newPlayerShelf)
        Settings.setShouldFollowSystemTheme(newUseSystemTheme)
        Settings.loadEmbeddedImages = newUseEmbeddedArtwork
        Settings.darkUpNextTheme = newUseDarkUpNextTheme

        Theme.sharedTheme.activeTheme = newTheme
        Theme.setPreferredLightTheme(newPreferredLightTheme, systemIsDark: false)
        Theme.setPreferredDarkTheme(newPreferredDarkTheme, systemIsDark: false)
        AutoplayHelper.shared.playedFrom(playlist: newAutoPlayPlaylist)

        // Enable settingsSync to flip `Settings` to use the new value
        try FeatureFlagOverrideStore().override(FeatureFlag.newSettingsStorage, withValue: true)

        try setupSettingsStore()
        SettingsStore.appSettings.importUserDefaults()

        XCTAssertEqual(newRowAction, Settings.primaryRowAction())
        XCTAssertEqual(newSwipeAction, Settings.primaryUpNextSwipeAction())
        XCTAssertEqual(newAppBadge, Settings.appBadge)
        XCTAssertEqual(newPlayedAfter.rawValue, Settings.autoArchivePlayedAfter())
        XCTAssertEqual(newInactiveAfter.rawValue, Settings.autoArchiveInactiveAfter())
        XCTAssertEqual(newEpisodeSortBy.rawValue, Settings.userEpisodeSortBy())
        XCTAssertEqual(newPlayerBookmarksSort, Settings.playerBookmarksSort.wrappedValue)
        XCTAssertEqual(newEpisodeBookmarksSort, Settings.episodeBookmarksSort.wrappedValue)
        XCTAssertEqual(newProfileBookmarksSort, Settings.profileBookmarksSort.wrappedValue)
        XCTAssertEqual(newHeadphonesNextAction, Settings.headphonesNextAction)
        XCTAssertEqual(newHeadphonesPreviousAction, Settings.headphonesPreviousAction)
        XCTAssertEqual(newHomeFolderSortOrder, Settings.homeFolderSortOrder())
        XCTAssertEqual(newPodcastBadgeType, Settings.podcastBadgeType())
        XCTAssertEqual(newAutoPlayPlaylist, AutoplayHelper.shared.lastPlaylist)
        XCTAssertEqual(newTheme, Theme.sharedTheme.activeTheme)
        XCTAssertEqual(newPreferredLightTheme, Theme.preferredLightTheme())
        XCTAssertEqual(newPreferredDarkTheme, Theme.preferredDarkTheme())

        XCTAssertEqual(newOpenLinks, Settings.openLinks)
        XCTAssertEqual(newShowArchived, Settings.showArchivedDefault())
        XCTAssertEqual(newSkipForward, Settings.skipForwardTime)
        XCTAssertEqual(newSkipBack, Settings.skipBackTime)
        XCTAssertEqual(newKeepScreenAwake, Settings.keepScreenAwake)
        XCTAssertEqual(newOpenPlayer, Settings.openPlayerAutomatically)
        XCTAssertEqual(newIntelligentResumption, Settings.intelligentResumption)
        XCTAssertEqual(newPlayupNextOnTap, Settings.playUpNextOnTap())
        XCTAssertEqual(newPlaybackActions, Settings.extraMediaSessionActionsEnabled())
        XCTAssertEqual(newLegacyBluetooth, Settings.legacyBluetoothModeEnabled())
        XCTAssertEqual(newMultiselectGesture, Settings.multiSelectGestureEnabled())
        XCTAssertEqual(newChapterTitles, Settings.publishChapterTitlesEnabled())
        XCTAssertEqual(newAutoplayEnabled, Settings.autoplay)
        XCTAssertEqual(newAutoplayEnabled, Settings.autoplay)
        XCTAssertEqual(newNotifications, UserDefaults.standard.bool(forKey: Constants.UserDefaults.pushEnabled))
        XCTAssertEqual(newAppBadgeFilter, Settings.appBadgeFilterUuid)
        XCTAssertEqual(newAutoarchiveIncludesStarred, Settings.archiveStarredEpisodes())
        XCTAssertEqual(newVolumeBoost, SettingsStore.appSettings.volumeBoost)
        XCTAssertEqual(newTrimSilence, SettingsStore.appSettings.trimSilence)
        XCTAssertEqual(newPlaybackSpeed, SettingsStore.appSettings.playbackSpeed)
        XCTAssertEqual(newFilesAutoUpNext, Settings.userEpisodeAutoAddToUpNext())
        XCTAssertEqual(newFilesAfterPlayingDeleteLocal, Settings.userEpisodeRemoveFileAfterPlaying())
        XCTAssertEqual(newFilesAfterPlayingDeleteCloud, Settings.userEpisodeRemoveFileAfterPlaying())
        XCTAssertEqual(newWarnDataUsage, !Settings.mobileDataAllowed())
        XCTAssertEqual(newAutoUpNextLimit, ServerSettings.autoAddToUpNextLimit())
        XCTAssertEqual(newAutoUpNextLimitReached, ServerSettings.onAutoAddLimitReached())
        XCTAssertEqual(newPrivacyAnalytics, Settings.analyticsOptOut())
        XCTAssertEqual(newMarketingOptIn, ServerSettings.marketingOptIn())
        XCTAssertEqual(newFreeGiftAcknowledgement, Settings.subscriptionCancelledAcknowledged())
        XCTAssertEqual(newGridOrder, Settings.homeFolderSortOrder())
        XCTAssertEqual(newGridLayout, Settings.libraryType())
        XCTAssertEqual(newPlayerShelf, Array(Settings.playerActions().prefix(upTo: newPlayerShelf.count))) // Default actions are appended so only look at set items
        XCTAssertEqual(newUseSystemTheme, Settings.shouldFollowSystemTheme())
        XCTAssertEqual(newUseEmbeddedArtwork, Settings.loadEmbeddedImages)
        XCTAssertEqual(newUseEmbeddedArtwork, Settings.darkUpNextTheme)
    }

    /// Tests that the default values are used when a value is missing from the JSON (such as when a key was added after writing the JSON object)
    func testDefaultValuesWhenMissing() throws {
        let json = "{ \"openLinks\": { \"value\": true, \"modifiedDate\": \"2024-03-28T13:49:51.141Z\"} }"
        let settings = try JSONDecoder().decode(AppSettings.self, from: json.data(using: .utf8)!)

        XCTAssertTrue(settings.openLinks, "Should contain new value from JSON")
        XCTAssertEqual(settings.autoArchivePlayed, .afterPlaying, "Should contain default value")
        XCTAssertTrue(settings.multiSelectGesture, "Should contain default value")
        XCTAssertEqual(settings.skipForward, 45, "Should contain default value")
    }
}
