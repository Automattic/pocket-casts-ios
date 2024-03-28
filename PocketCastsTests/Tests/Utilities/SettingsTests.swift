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
    }
}
