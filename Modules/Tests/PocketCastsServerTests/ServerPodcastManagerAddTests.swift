@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB

final class ServerPodcastManagerAddTests: XCTestCase {
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

    func testAddingAPodcastSavesItsEpisodes() throws {
        let podcastInfo: [String: Any] = [
            "podcast": [
                "uuid": "podcast-1",
                "title": "Podcast",
                "episodes": [
                    ["uuid": "old", "title": "Old", "published": "2026-01-01T00:00:00Z"],
                    ["uuid": "newest", "title": "Newest", "published": "2026-03-01T00:00:00Z"],
                    ["uuid": "middle", "title": "Middle", "published": "2026-02-01T00:00:00Z"]
                ]
            ]
        ]

        let added = expectation(description: "added")
        var result = false
        ServerPodcastManager.shared.addFromJson(podcastUuid: "podcast-1", lastModified: nil, podcastInfo: podcastInfo, subscribe: true, autoDownloads: 0, fromSync: true) {
            result = $0
            added.fulfill()
        }
        wait(for: [added], timeout: 10)
        XCTAssertTrue(result)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: "podcast-1"))
        let episodes = dataManager.allEpisodes(forPodcastId: podcast.id)
        XCTAssertEqual(episodes.map(\.uuid).sorted(), ["middle", "newest", "old"])
        XCTAssertTrue(episodes.allSatisfy { $0.podcastUuid == "podcast-1" })
        XCTAssertEqual(podcast.latestEpisodeUuid, "newest")
    }
}
