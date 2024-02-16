import XCTest
@testable import podcasts
@testable import PocketCastsServer
import PocketCastsDataModel

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

    func testPlayerActions() throws {
        let unknownString = "test"
        try override(flag: .settingsSync, value: true)
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

        try reset(flag: .settingsSync)
    }

    func testOldPlayerActions() throws {
        try override(flag: .settingsSync, value: false)

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

        try reset(flag: .settingsSync)
    }

    func testImportOldPlayerActions() throws {
        // Start with disabled settingsSync
        try override(flag: .settingsSync, value: false)

        Settings.updatePlayerActions(PlayerAction.defaultActions.filter { $0.isAvailable })
        Settings.updatePlayerActions([.addBookmark, .markPlayed]) // This update is tested in testOldPlayerActions

        // Enable settingsSync to flip `Settings` to use the new value
        try FeatureFlagOverrideStore().override(FeatureFlag.settingsSync, withValue: true)

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

        try reset(flag: .settingsSync)
    }
}
