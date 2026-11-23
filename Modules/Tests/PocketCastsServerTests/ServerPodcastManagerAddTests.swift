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
