import XCTest

@testable import podcasts

class AutoplayHelperTests: XCTestCase {
    var autoplayHelper: AutoplayHelper!

    override func setUp() {
        autoplayHelper = AutoplayHelper(
            userDefaults: UserDefaults(suiteName: "\(Int.random(in: 0..<1000))")!
        )
    }

    func testInitialValueIsNil() {
        XCTAssertNil(autoplayHelper.lastPlaylist)
    }

    func testSaveLatestPlaylist() {
        autoplayHelper.playedAt(playlist: .podcast(uuid: "fake-uuid"))

        switch autoplayHelper.lastPlaylist {
        case .podcast(uuid: let uuid):
            XCTAssertTrue(uuid == "fake-uuid")
        default:
            XCTFail()
        }
    }

    func testCorrectlyUpdateLatestPlaylist() {
        autoplayHelper.playedAt(playlist: .podcast(uuid: "fake-uuid"))

        autoplayHelper.playedAt(playlist: .starred)

        switch autoplayHelper.lastPlaylist {
        case .starred:
            break
        default:
            XCTFail()
        }
    }

    func testCorrectlyRemoveValueIfPlaylistIsUnknown() {
        autoplayHelper.playedAt(playlist: .podcast(uuid: "fake-uuid"))

        autoplayHelper.playedAt(playlist: nil)

        XCTAssertNil(autoplayHelper.lastPlaylist)
    }
}
