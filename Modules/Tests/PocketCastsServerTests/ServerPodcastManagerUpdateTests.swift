@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB

final class ServerPodcastManagerUpdateTests: XCTestCase {
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

    func testUpdateSavesMissingAndChangedEpisodes() throws {
        let podcast = Podcast()
        podcast.uuid = "podcast-1"
        podcast.subscribed = 0
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)

        let existing = Episode()
        existing.uuid = "existing"
        existing.podcast_id = podcast.id
        existing.podcastUuid = podcast.uuid
        existing.addedDate = Date()
        existing.title = "Old title"
        existing.publishedDate = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z"))
        dataManager.save(episode: existing)

        let podcastInfo: [String: Any] = [
            "podcast": [
                "episodes": [
                    ["uuid": "new-1", "title": "New 1", "published": "2026-02-01T00:00:00Z", "duration": 120.0],
                    ["uuid": "new-2", "title": "New 2", "published": "2026-03-01T00:00:00Z"],
                    ["uuid": "existing", "title": "New title", "published": "2026-01-01T00:00:00Z"],
                    ["uuid": "new-1", "title": "New 1 again", "published": "2026-02-01T00:00:00Z"]
                ]
            ]
        ]

        ServerPodcastManager.shared.update(podcast: podcast, podcastInfo: podcastInfo, lastModified: nil, addMissingEpisodes: false)

        let episodes = dataManager.findEpisodesWhere(customWhere: "podcastUuid = ?", arguments: [podcast.uuid])
        XCTAssertEqual(episodes.map(\.uuid).sorted(), ["existing", "new-1", "new-2"])
        XCTAssertFalse(episodes.contains { $0.id == 0 })

        let byUuid = Dictionary(episodes.map { ($0.uuid, $0) }, uniquingKeysWith: { first, _ in first })
        XCTAssertEqual(byUuid["new-1"]?.title, "New 1 again")
        XCTAssertEqual(byUuid["new-1"]?.duration, 120)
        XCTAssertEqual(byUuid["new-2"]?.title, "New 2")
        XCTAssertEqual(byUuid["existing"]?.title, "New title")
        XCTAssertEqual(byUuid["existing"]?.id, existing.id)

        XCTAssertEqual(podcast.latestEpisodeUuid, "new-2")
    }
}
