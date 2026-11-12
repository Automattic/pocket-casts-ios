@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB

final class NewPodcastDefaultsTests: XCTestCase {
    private var originalDataManager: DataManager!
    private var dataManager: DataManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalDataManager = DataManager.shared
        let dbPath = NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite")
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: dbPath)))
        DataManager.shared = dataManager
    }

    override func tearDownWithError() throws {
        DataManager.shared = originalDataManager
        dataManager = nil
        originalDataManager = nil

        try super.tearDownWithError()
    }

    func testAddingAPodcastSavesItsNewestEpisodeAndDefaults() throws {
        let other = Podcast()
        other.uuid = "other"
        other.subscribed = 1
        other.pushEnabled = true
        other.autoDownloadSetting = AutoDownloadSetting.off.rawValue
        other.addedDate = Date()
        dataManager.save(podcast: other)

        let podcastInfo: [String: Any] = [
            "podcast": [
                "uuid": "podcast-1",
                "title": "Podcast",
                "episodes": [
                    ["uuid": "old", "title": "Old", "published": "2026-01-01T00:00:00Z"],
                    ["uuid": "newest", "title": "Newest", "published": "2026-03-01T00:00:00Z"]
                ]
            ]
        ]
        let added = expectation(description: "added")
        ServerPodcastManager.shared.addFromJson(podcastUuid: "podcast-1", lastModified: nil, podcastInfo: podcastInfo, subscribe: true, autoDownloads: 0, fromSync: true) { _ in
            added.fulfill()
        }
        wait(for: [added], timeout: 10)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: "podcast-1"))
        XCTAssertEqual(podcast.latestEpisodeUuid, "newest")
        XCTAssertEqual(podcast.latestEpisodeDate, ISO8601DateFormatter().date(from: "2026-03-01T00:00:00Z"))
        XCTAssertTrue(podcast.pushEnabled, "Every other subscribed podcast has notifications on")
        XCTAssertEqual(podcast.autoDownloadSetting, AutoDownloadSetting.off.rawValue)
    }
}
