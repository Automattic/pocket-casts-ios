import XCTest

@testable import PocketCastsServer
@testable import podcasts

class AutoplayHelperTests: XCTestCase {
    var autoplayHelper: AutoplayHelper!

    override func setUp() {
        let userDefaults = UserDefaults(suiteName: "\(Int.random(in: 0..<1000))")!
        autoplayHelper = AutoplayHelper(
            userDefaults: userDefaults
        )
        SettingsStore.appSettings = SettingsStore(userDefaults: userDefaults, key: "app_settings", value: AppSettings.defaults)
    }

    func testInitialValueIsNil() {
        XCTAssertNil(autoplayHelper.lastPlaylist)
    }

    func testSaveLatestPlaylist() {
        autoplayHelper.playedFrom(playlist: .podcast(uuid: "fake-uuid"))

        switch autoplayHelper.lastPlaylist {
        case .podcast(uuid: let uuid):
            XCTAssertTrue(uuid == "fake-uuid")
        default:
            XCTFail()
        }
    }

    func testCorrectlyUpdateLatestPlaylist() {
        autoplayHelper.playedFrom(playlist: .podcast(uuid: "fake-uuid"))

        autoplayHelper.playedFrom(playlist: .starred)

        switch autoplayHelper.lastPlaylist {
        case .starred:
            break
        default:
            XCTFail()
        }
    }

    func testCorrectlyRemoveValueIfPlaylistIsUnknown() {
        autoplayHelper.playedFrom(playlist: .podcast(uuid: "fake-uuid"))

        autoplayHelper.playedFrom(playlist: nil)

        XCTAssertNil(autoplayHelper.lastPlaylist)
    }
}
