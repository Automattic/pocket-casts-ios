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

    func testAddingAPodcastUpdatesExistingPlaceholderWithoutDuplicating() throws {
        let podcastUuid = "podcast-placeholder-\(UUID().uuidString)"
        let placeholder = Episode()
        placeholder.uuid = "ep-1"
        placeholder.podcastUuid = podcastUuid
        placeholder.podcast_id = 0
        placeholder.title = "Placeholder Title"
        placeholder.wasDeleted = true
        placeholder.episodeStatus = 0
        placeholder.playingStatus = 0
        placeholder.addedDate = Date(timeIntervalSince1970: 1000)
        dataManager.save(episode: placeholder)
        let originalId = placeholder.id

        let podcastInfo: [String: Any] = [
            "podcast": [
                "uuid": podcastUuid,
                "title": "Podcast",
                "episodes": [
                    [
                        "uuid": "ep-1",
                        "title": "Real Episode 1",
                        "url": "https://example.com/1.mp3",
                        "file_type": "audio/mp3",
                        "file_size": Int64(4096),
                        "duration": 180.0,
                        "published": "2026-01-01T00:00:00Z"
                    ],
                    [
                        "uuid": "ep-2",
                        "title": "Real Episode 2",
                        "url": "https://example.com/2.mp3",
                        "published": "2026-02-01T00:00:00Z"
                    ]
                ]
            ]
        ]

        let added = expectation(description: "added")
        var result = false
        ServerPodcastManager.shared.addFromJson(podcastUuid: podcastUuid, lastModified: nil, podcastInfo: podcastInfo, subscribe: false, autoDownloads: 0, fromSync: true) {
            result = $0
            added.fulfill()
        }
        wait(for: [added], timeout: 10)
        XCTAssertTrue(result)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true))
        let matchingRows = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: ["ep-1"])
        XCTAssertEqual(matchingRows.count, 1)

        let recovered = try XCTUnwrap(matchingRows.first)
        XCTAssertEqual(recovered.id, originalId)
        XCTAssertFalse(recovered.wasDeleted)
        XCTAssertEqual(recovered.podcast_id, podcast.id)
        XCTAssertEqual(recovered.episodeStatus, DownloadStatus.notDownloaded.rawValue)
        XCTAssertEqual(recovered.playingStatus, PlayingStatus.notPlayed.rawValue)
        XCTAssertEqual(recovered.title, "Real Episode 1")
        XCTAssertEqual(recovered.fileType, "audio/mp3")
        XCTAssertEqual(recovered.sizeInBytes, 4096)
        XCTAssertEqual(recovered.duration, 180.0)

        let visibleEpisodes = dataManager.allEpisodes(forPodcastId: podcast.id)
        XCTAssertEqual(visibleEpisodes.map(\.uuid).sorted(), ["ep-1", "ep-2"])
    }

    func testAddMissingPodcastAndEpisodeRecoversDeletedPlaceholderWhenShouldUpdateIsFalse() throws {
        let podcastUuid = "podcast-recover-ep-\(UUID().uuidString)"
        let episodeUuid = "ep-recover-\(UUID().uuidString)"

        let podcast = Podcast()
        podcast.uuid = podcastUuid
        podcast.subscribed = 0
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)

        let placeholder = Episode()
        placeholder.uuid = episodeUuid
        placeholder.podcastUuid = podcastUuid
        placeholder.podcast_id = 0
        placeholder.title = "Unavailable Placeholder"
        placeholder.wasDeleted = true
        placeholder.episodeStatus = 0
        placeholder.playingStatus = 0
        placeholder.addedDate = Date()
        dataManager.save(episode: placeholder)

        AddTestsMockURLProtocol.responseJson = [
            "podcast": [
                "uuid": podcastUuid,
                "title": "Podcast",
                "episodes": [
                    [
                        "uuid": episodeUuid,
                        "title": "Recovered Episode",
                        "url": "https://example.com/recovered.mp3",
                        "file_type": "audio/mp3",
                        "file_size": 2048,
                        "duration": 240.0,
                        "published": "2026-01-05T00:00:00Z"
                    ]
                ]
            ]
        ]
        URLProtocol.registerClass(AddTestsMockURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(AddTestsMockURLProtocol.self)
            AddTestsMockURLProtocol.responseJson = nil
        }

        let completed = expectation(description: "addMissingPodcastAndEpisode")
        ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid, shouldUpdateEpisode: false) { _ in
            completed.fulfill()
        }
        wait(for: [completed], timeout: 10)

        let recovered = try XCTUnwrap(dataManager.findEpisode(uuid: episodeUuid))
        XCTAssertEqual(recovered.id, placeholder.id)
        XCTAssertFalse(recovered.wasDeleted)
        XCTAssertEqual(recovered.podcast_id, podcast.id)
        XCTAssertEqual(recovered.episodeStatus, DownloadStatus.notDownloaded.rawValue)
        XCTAssertEqual(recovered.playingStatus, PlayingStatus.notPlayed.rawValue)
        XCTAssertEqual(recovered.title, "Recovered Episode")
    }

    func testAddingAPodcastRepointsEpisodesKeptFromADeletedPodcast() throws {
        let podcastUuid = "podcast-readded-\(UUID().uuidString)"

        // An episode the user played, left behind when its podcast row was deleted
        let kept = Episode()
        kept.uuid = "ep-kept"
        kept.podcastUuid = podcastUuid
        kept.podcast_id = 999_999
        kept.title = "Kept Episode"
        kept.episodeStatus = DownloadStatus.notDownloaded.rawValue
        kept.playingStatus = PlayingStatus.inProgress.rawValue
        kept.playedUpTo = 42
        kept.addedDate = Date()
        dataManager.save(episode: kept)

        let podcastInfo: [String: Any] = [
            "podcast": [
                "uuid": podcastUuid,
                "title": "Podcast",
                "episodes": [
                    ["uuid": "ep-kept", "title": "Kept Episode", "published": "2026-01-01T00:00:00Z"],
                    ["uuid": "ep-new", "title": "New Episode", "published": "2026-02-01T00:00:00Z"]
                ]
            ]
        ]

        let added = expectation(description: "added")
        ServerPodcastManager.shared.addFromJson(podcastUuid: podcastUuid, lastModified: nil, podcastInfo: podcastInfo, subscribe: false, autoDownloads: 0, fromSync: true) { _ in
            added.fulfill()
        }
        wait(for: [added], timeout: 10)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true))
        let rows = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: ["ep-kept"])
        XCTAssertEqual(rows.map(\.id), [kept.id])

        let recovered = try XCTUnwrap(rows.first)
        XCTAssertEqual(recovered.podcast_id, podcast.id)
        XCTAssertEqual(recovered.playingStatus, PlayingStatus.inProgress.rawValue)
        XCTAssertEqual(recovered.playedUpTo, 42)

        let visibleEpisodes = dataManager.allEpisodes(forPodcastId: podcast.id)
        XCTAssertEqual(visibleEpisodes.map(\.uuid).sorted(), ["ep-kept", "ep-new"])
    }

    func testAddMissingPodcastAndEpisodeDropsPlaceholderThatDuplicatesAVisibleEpisode() throws {
        let podcast = savePodcast()
        let episodeUuid = "ep-duplicated-\(UUID().uuidString)"

        // Before #5701 was fixed, a placeholder and a visible copy of it were both saved.
        // The placeholder gets the lower id, so `findEpisode(uuid:)` returns it.
        let placeholder = savePlaceholder(id: 1, uuid: episodeUuid, podcastUuid: podcast.uuid)
        let visible = saveVisibleEpisode(id: 2, uuid: episodeUuid, podcast: podcast)
        XCTAssertEqual(dataManager.findEpisode(uuid: episodeUuid)?.id, placeholder.id)

        addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcast.uuid)

        let rows = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: [episodeUuid])
        XCTAssertEqual(rows.map(\.id), [visible.id])
        XCTAssertEqual(rows.first?.wasDeleted, false)
        XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).map(\.uuid), [episodeUuid])
    }

    func testAddMissingPodcastAndEpisodeKeepsDuplicatePlaceholderThatHoldsUserState() throws {
        let podcast = savePodcast()
        let episodeUuid = "ep-duplicated-state-\(UUID().uuidString)"

        let placeholder = savePlaceholder(id: 1, uuid: episodeUuid, podcastUuid: podcast.uuid) { episode in
            // Synced progress landed on the placeholder, since uuid lookups returned it
            episode.playingStatus = PlayingStatus.inProgress.rawValue
            episode.playedUpTo = 120
        }
        let visible = saveVisibleEpisode(id: 2, uuid: episodeUuid, podcast: podcast)

        addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcast.uuid)

        let rows = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: [episodeUuid])
        XCTAssertEqual(rows.map(\.id), [placeholder.id])
        XCTAssertFalse(rows.contains { $0.id == visible.id })

        let survivor = try XCTUnwrap(rows.first)
        XCTAssertFalse(survivor.wasDeleted)
        XCTAssertEqual(survivor.podcast_id, podcast.id)
        XCTAssertEqual(survivor.playingStatus, PlayingStatus.inProgress.rawValue)
        XCTAssertEqual(survivor.playedUpTo, 120)
        XCTAssertEqual(survivor.episodeStatus, DownloadStatus.notDownloaded.rawValue)
        XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).map(\.uuid), [episodeUuid])
    }

    // MARK: - Helpers

    private func savePodcast() -> Podcast {
        let podcast = Podcast()
        podcast.uuid = "podcast-\(UUID().uuidString)"
        podcast.subscribed = 0
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)
        return podcast
    }

    /// Saves a row shaped like the ones playlist sync saves for episodes it hasn't loaded yet.
    @discardableResult
    private func savePlaceholder(id: Int64, uuid: String, podcastUuid: String, configure: (Episode) -> Void = { _ in }) -> Episode {
        let episode = Episode()
        episode.id = id
        episode.uuid = uuid
        episode.podcastUuid = podcastUuid
        episode.podcast_id = 0
        episode.title = "Placeholder"
        episode.wasDeleted = true
        episode.episodeStatus = 0
        episode.playingStatus = 0
        episode.addedDate = Date()
        configure(episode)
        dataManager.save(episode: episode)
        return episode
    }

    @discardableResult
    private func saveVisibleEpisode(id: Int64, uuid: String, podcast: Podcast) -> Episode {
        let episode = Episode()
        episode.id = id
        episode.uuid = uuid
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.title = "Visible"
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.addedDate = Date()
        dataManager.save(episode: episode)
        return episode
    }

    private func addMissingPodcastAndEpisode(episodeUuid: String, podcastUuid: String) {
        AddTestsMockURLProtocol.responseJson = [
            "podcast": [
                "uuid": podcastUuid,
                "title": "Podcast",
                "episodes": [
                    [
                        "uuid": episodeUuid,
                        "title": "Server Episode",
                        "url": "https://example.com/episode.mp3",
                        "published": "2026-01-05T00:00:00Z"
                    ]
                ]
            ]
        ]
        URLProtocol.registerClass(AddTestsMockURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(AddTestsMockURLProtocol.self)
            AddTestsMockURLProtocol.responseJson = nil
        }

        let completed = expectation(description: "addMissingPodcastAndEpisode")
        ServerPodcastManager.shared.addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid, shouldUpdateEpisode: false) { _ in
            completed.fulfill()
        }
        wait(for: [completed], timeout: 10)
    }
}

private final class AddTestsMockURLProtocol: URLProtocol {
    static var responseJson: [String: Any]?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let json = Self.responseJson,
              let data = try? JSONSerialization.data(withJSONObject: json),
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
