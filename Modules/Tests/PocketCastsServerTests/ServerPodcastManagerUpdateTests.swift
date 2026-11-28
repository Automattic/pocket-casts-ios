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

    func testUpdateClearsWasDeletedAndRepairsPlaceholderFields() throws {
        let podcast = Podcast()
        podcast.uuid = "podcast-recover-\(UUID().uuidString)"
        podcast.subscribed = 0
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)

        let recoverable = Episode()
        recoverable.uuid = "recoverable-ep"
        recoverable.podcast_id = 0
        recoverable.podcastUuid = podcast.uuid
        recoverable.addedDate = Date()
        recoverable.title = "Placeholder Title"
        recoverable.wasDeleted = true
        recoverable.episodeStatus = 0
        recoverable.playingStatus = 0
        dataManager.save(episode: recoverable)

        let genuinelyDeleted = Episode()
        genuinelyDeleted.uuid = "genuinely-deleted-ep"
        genuinelyDeleted.podcast_id = podcast.id
        genuinelyDeleted.podcastUuid = podcast.uuid
        genuinelyDeleted.addedDate = Date()
        genuinelyDeleted.title = "Deleted By Creator"
        genuinelyDeleted.wasDeleted = true
        dataManager.save(episode: genuinelyDeleted)

        let podcastInfo: [String: Any] = [
            "podcast": [
                "episodes": [
                    [
                        "uuid": "recoverable-ep",
                        "title": "Restored Title",
                        "url": "https://example.com/restored.mp3",
                        "file_type": "audio/mp3",
                        "file_size": Int64(12345),
                        "duration": 600.0,
                        "published": "2026-01-15T00:00:00Z"
                    ]
                ]
            ]
        ]

        ServerPodcastManager.shared.update(podcast: podcast, podcastInfo: podcastInfo, lastModified: nil, addMissingEpisodes: false)

        let updated = try XCTUnwrap(dataManager.findEpisode(uuid: "recoverable-ep"))
        XCTAssertEqual(updated.id, recoverable.id)
        XCTAssertFalse(updated.wasDeleted)
        XCTAssertEqual(updated.podcast_id, podcast.id)
        XCTAssertEqual(updated.episodeStatus, DownloadStatus.notDownloaded.rawValue)
        XCTAssertEqual(updated.playingStatus, PlayingStatus.notPlayed.rawValue)
        XCTAssertEqual(updated.title, "Restored Title")
        XCTAssertEqual(updated.downloadUrl, "https://example.com/restored.mp3")
        XCTAssertEqual(updated.fileType, "audio/mp3")
        XCTAssertEqual(updated.sizeInBytes, 12345)
        XCTAssertEqual(updated.duration, 600.0)

        let stillDeleted = try XCTUnwrap(dataManager.findEpisode(uuid: "genuinely-deleted-ep"))
        XCTAssertTrue(stillDeleted.wasDeleted)

        let visibleEpisodes = dataManager.allEpisodes(forPodcastId: podcast.id)
        XCTAssertEqual(visibleEpisodes.map(\.uuid), ["recoverable-ep"])
    }

    func testUpdateDropsPlaceholderThatDuplicatesAVisibleEpisode() throws {
        let podcast = Podcast()
        podcast.uuid = "podcast-duplicate-\(UUID().uuidString)"
        podcast.subscribed = 0
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)

        // Before #5701 was fixed, a placeholder and a visible copy of it were both saved.
        // The placeholder gets the lower id, so `findEpisode(uuid:)` returns it.
        let placeholder = Episode()
        placeholder.id = 1
        placeholder.uuid = "duplicated-ep"
        placeholder.podcastUuid = podcast.uuid
        placeholder.podcast_id = 0
        placeholder.addedDate = Date()
        placeholder.title = "Placeholder"
        placeholder.wasDeleted = true
        placeholder.episodeStatus = 0
        placeholder.playingStatus = 0
        dataManager.save(episode: placeholder)

        let visible = Episode()
        visible.id = 2
        visible.uuid = "duplicated-ep"
        visible.podcastUuid = podcast.uuid
        visible.podcast_id = podcast.id
        visible.addedDate = Date()
        visible.title = "Visible"
        visible.episodeStatus = DownloadStatus.notDownloaded.rawValue
        visible.playingStatus = PlayingStatus.notPlayed.rawValue
        dataManager.save(episode: visible)
        XCTAssertEqual(dataManager.findEpisode(uuid: "duplicated-ep")?.id, placeholder.id)

        let podcastInfo: [String: Any] = [
            "podcast": [
                "episodes": [
                    ["uuid": "duplicated-ep", "title": "Server Title", "published": "2026-01-15T00:00:00Z"]
                ]
            ]
        ]

        ServerPodcastManager.shared.update(podcast: podcast, podcastInfo: podcastInfo, lastModified: nil, addMissingEpisodes: false)

        let rows = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: ["duplicated-ep"])
        XCTAssertEqual(rows.map(\.id), [visible.id])
        XCTAssertEqual(rows.first?.wasDeleted, false)
        XCTAssertEqual(rows.first?.title, "Server Title")
        XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).map(\.uuid), ["duplicated-ep"])
    }
}
