import XCTest
@testable import podcasts
@testable import PocketCastsServer
import PocketCastsDataModel

final class SettingsTests: XCTestCase {

    private let userDefaultsSuiteName = "PocketCasts-SettingsTests"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    func testPlayerActions() throws {
        let originalSettingsSync = FeatureFlag.settingsSync.enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: true)
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable }) // Set defaults
        let unknownString = "test"

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
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: originalSettingsSync)
    }

    func testOldPlayerActions() throws {
        let originalSettingsSync = FeatureFlag.settingsSync.enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: false)
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
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: originalSettingsSync)
    }

    func testImportOldPlayerActions() throws {
        let originalSettingsSync = FeatureFlag.settingsSync.enabled

        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: false)
        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable })
        Settings.updatePlayerActions([.addBookmark, .markPlayed]) // This update is tested in testOldPlayerActions
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: true)

        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
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
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: originalSettingsSync)
    }
}
