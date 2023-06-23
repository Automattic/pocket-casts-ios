import XCTest

@testable import podcasts

class AutoplayHelperTests: XCTestCase {
    var autoplayHelper: AutoplayHelper!
    var uiApplicationMock: UIApplicationMock!

    override func setUp() {
        uiApplicationMock = UIApplicationMock()

        autoplayHelper = AutoplayHelper(
            userDefaults: UserDefaults(suiteName: "\(Int.random(in: 0..<1000))")!,
            topViewControllerGetter: uiApplicationMock
        )
    }

    func testInitialValueIsNil() {
        XCTAssertNil(autoplayHelper.lastPlaylist)
    }

    func testSaveLatestPlaylist() {
        autoplayHelper.savePlaylist()

        switch autoplayHelper.lastPlaylist {
        case .podcast(uuid: let uuid):
            XCTAssertTrue(uuid == "fake-uuid")
        default:
            XCTFail()
        }
    }

    func testCorrectlyUpdateLatestPlaylist() {
        autoplayHelper.savePlaylist()

        uiApplicationMock.playlist = .listeningHistory
        autoplayHelper.savePlaylist()

        switch autoplayHelper.lastPlaylist {
        case .listeningHistory:
            break
        default:
            XCTFail()
        }
    }

    func testCorrectlyRemoveValueIfPlaylistIsUnknown() {
        autoplayHelper.savePlaylist()

        uiApplicationMock.playlist = nil
        autoplayHelper.savePlaylist()

        XCTAssertNil(autoplayHelper.lastPlaylist)
    }
}

// MARK: - Mocks

class UIApplicationMock: TopViewControllerGetter {
    var playlist: EpisodesDataManager.Playlist? = .podcast(uuid: "fake-uuid")

    func getTopViewController(base: UIViewController? = SceneHelper.rootViewController()) -> UIViewController? {
        if let playlist {
            return ViewControllerMock(playlist: playlist)
        }

        return nil
    }
}

class ViewControllerMock: UIViewController, PlaylistAutoplay {
    var playlist: EpisodesDataManager.Playlist

    init(playlist: EpisodesDataManager.Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
