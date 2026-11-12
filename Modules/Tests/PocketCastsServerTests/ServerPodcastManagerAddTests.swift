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

    func testLatestEpisodesMatchTheDatabaseOrder() throws {
        let podcast = Podcast()
        podcast.uuid = "podcast-1"
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)

        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let specs: [(uuid: String, published: Date?, added: Date, deleted: Bool)] = [
            ("old", base, base, false),
            ("tie-added-first", base.addingTimeInterval(100), base, false),
            ("tie-added-last", base.addingTimeInterval(100), base.addingTimeInterval(5), false),
            ("newest-but-deleted", base.addingTimeInterval(200), base, true),
            ("no-date", nil, base.addingTimeInterval(10), false),
            ("middle", base.addingTimeInterval(50), base, false)
        ]
        let episodes = specs.map { spec in
            let episode = Episode()
            episode.uuid = spec.uuid
            episode.podcast_id = podcast.id
            episode.podcastUuid = podcast.uuid
            episode.publishedDate = spec.published
            episode.addedDate = spec.added
            episode.wasDeleted = spec.deleted
            return episode
        }
        dataManager.bulkSave(episodes: episodes)

        for limit in [1, 3, specs.count] {
            XCTAssertEqual(ServerPodcastManager.latestEpisodes(in: episodes, limit: limit).map(\.uuid), podcast.latestEpisodes(limit: limit).map(\.uuid), "limit \(limit)")
        }
        XCTAssertEqual(ServerPodcastManager.latestEpisodes(in: episodes, limit: specs.count).map(\.uuid), ["tie-added-last", "tie-added-first", "middle", "old", "no-date"])
    }

    func testAddingAPodcastSavesItsNewestEpisodeAsTheLatest() throws {
        let podcastInfo: [String: Any] = [
            "podcast": [
                "uuid": "podcast-1",
                "title": "Podcast",
                "episodes": [
                    ["uuid": "old", "title": "Old", "published": "2026-01-01T00:00:00Z"],
                    ["uuid": "newest", "title": "Newest", "published": "2026-03-01T00:00:00Z"],
                    ["uuid": "no-date", "title": "No date"],
                    ["uuid": "middle", "title": "Middle", "published": "2026-02-01T00:00:00Z"]
                ]
            ]
        ]

        try add(podcastInfo)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: "podcast-1"))
        XCTAssertEqual(podcast.latestEpisodeUuid, "newest")
        XCTAssertEqual(podcast.latestEpisodeDate, ISO8601DateFormatter().date(from: "2026-03-01T00:00:00Z"))
        XCTAssertEqual(podcast.latestEpisodeUuid, podcast.latestEpisodes().first?.uuid)
        XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).count, 4)
    }

    func testAddingAPodcastSavesItsDefaults() throws {
        let other = Podcast()
        other.uuid = "other"
        other.subscribed = 1
        other.pushEnabled = true
        other.autoDownloadSetting = AutoDownloadSetting.off.rawValue
        other.addedDate = Date()
        dataManager.save(podcast: other)

        try add(["podcast": ["uuid": "podcast-1", "title": "Podcast", "episodes": [["uuid": "episode-1", "published": "2026-01-01T00:00:00Z"]]]])

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: "podcast-1"))
        XCTAssertTrue(podcast.pushEnabled, "Every other subscribed podcast has notifications on")
        XCTAssertEqual(podcast.autoDownloadSetting, AutoDownloadSetting.off.rawValue)
        XCTAssertEqual(podcast.latestEpisodeUuid, "episode-1")
    }

    private func add(_ podcastInfo: [String: Any]) throws {
        let added = expectation(description: "added")
        var result = false
        ServerPodcastManager.shared.addFromJson(podcastUuid: "podcast-1", lastModified: nil, podcastInfo: podcastInfo, subscribe: true, autoDownloads: 0, fromSync: true) {
            result = $0
            added.fulfill()
        }
        wait(for: [added], timeout: 10)
        XCTAssertTrue(result)
    }
}
