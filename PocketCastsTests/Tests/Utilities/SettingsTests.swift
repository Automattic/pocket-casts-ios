import XCTest
@testable import podcasts
@testable import PocketCastsServer

final class SettingsTests: XCTestCase {

    private let userDefaultsSuiteName = "PocketCasts-SettingsTests"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
    }

    func testPlayerActions() throws {
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName), "User Defaults suite should load")
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
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
    }
}
