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

    func testAddingMissingEpisodesOfOnePodcastConcurrentlySavesThePodcastOnce() throws {
        let episodeCount = 8

        for _ in 0..<25 {
            let podcastUuid = UUID().uuidString
            let episodeUuids = (0..<episodeCount).map { _ in UUID().uuidString }
            let barrier = Barrier(count: episodeCount)
            let manager = ServerPodcastManager(urlConnection: URLConnection(mockHandler: { request in
                barrier.arriveAndWait()
                return try Self.findByEpisodeResponse(for: request)
            }))

            let group = DispatchGroup()
            for episodeUuid in episodeUuids {
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    manager.addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid)
                    group.leave()
                }
            }
            XCTAssertEqual(group.wait(timeout: .now() + 30), .success)

            try assertOnePodcastRow(uuid: podcastUuid, containing: episodeUuids, subscribed: false)
        }
    }

    func testSubscribingWhileAddingMissingEpisodesSavesThePodcastOnce() throws {
        let episodeCount = 4

        for _ in 0..<25 {
            let podcastUuid = UUID().uuidString
            let episodeUuids = (0..<episodeCount).map { _ in UUID().uuidString }
            let subscribedEpisodeUuid = UUID().uuidString
            let barrier = Barrier(count: episodeCount + 1)
            let manager = ServerPodcastManager(urlConnection: URLConnection(mockHandler: { request in
                barrier.arriveAndWait()
                return try Self.findByEpisodeResponse(for: request)
            }))

            let group = DispatchGroup()
            for episodeUuid in episodeUuids {
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    manager.addMissingPodcastAndEpisode(episodeUuid: episodeUuid, podcastUuid: podcastUuid)
                    group.leave()
                }
            }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                barrier.arriveAndWait()
                manager.addFromJson(podcastUuid: podcastUuid, lastModified: nil, podcastInfo: Self.podcastInfo(podcastUuid: podcastUuid, episodeUuid: subscribedEpisodeUuid), subscribe: true, autoDownloads: 0, fromSync: true) { _ in
                    group.leave()
                }
            }
            XCTAssertEqual(group.wait(timeout: .now() + 30), .success)

            try assertOnePodcastRow(uuid: podcastUuid, containing: episodeUuids, subscribed: true)
        }
    }

    func testAddingAMissingEpisodeKeepsTheSettingsOfAPodcastWeAlreadyHave() throws {
        let podcast = Podcast()
        podcast.uuid = "podcast-1"
        podcast.subscribed = 1
        podcast.autoDownloadSetting = AutoDownloadSetting.latest.rawValue
        podcast.showArchived = true
        dataManager.save(podcast: podcast)

        let episode = Episode()
        episode.uuid = "episode-1"
        episode.podcast_id = podcast.id
        episode.podcastUuid = podcast.uuid
        episode.publishedDate = Date()
        dataManager.save(episode: episode)

        let manager = ServerPodcastManager(urlConnection: URLConnection(mockHandler: { try Self.findByEpisodeResponse(for: $0) }))
        manager.addMissingPodcast(episodeUuid: "episode-2", podcastUuid: podcast.uuid)

        let savedPodcast = try XCTUnwrap(dataManager.findPodcast(uuid: podcast.uuid))
        XCTAssertEqual(savedPodcast.autoDownloadSetting, AutoDownloadSetting.latest.rawValue)
        XCTAssertTrue(savedPodcast.showArchived)
    }

    // MARK: - Helpers

    private func assertOnePodcastRow(uuid podcastUuid: String, containing episodeUuids: [String], subscribed: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        let podcastRows = dataManager.count(query: "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE uuid = ?", values: [podcastUuid])
        XCTAssertEqual(podcastRows, 1, "podcast rows", file: file, line: line)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true), file: file, line: line)
        XCTAssertEqual(podcast.isSubscribed(), subscribed, file: file, line: line)
        let episodes = dataManager.allEpisodes(forPodcastId: podcast.id)
        XCTAssertTrue(Set(episodes.map(\.uuid)).isSuperset(of: episodeUuids), "every missing episode is attached to the podcast row", file: file, line: line)
    }

    /// What `mobile/podcast/findbyepisode/<podcast>/<episode>` returns: the podcast with only that episode.
    private static func findByEpisodeResponse(for request: URLRequest) throws -> (Data?, URLResponse?) {
        let url = try XCTUnwrap(request.url)
        let components = url.pathComponents
        let episodeUuid = try XCTUnwrap(components.last)
        let podcastUuid = components[components.count - 2]
        let data = try JSONSerialization.data(withJSONObject: podcastInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid))
        return (data, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
    }

    private static func podcastInfo(podcastUuid: String, episodeUuid: String) -> [String: Any] {
        [
            "podcast": [
                "uuid": podcastUuid,
                "title": "Podcast",
                "episodes": [
                    ["uuid": episodeUuid, "title": "Episode", "published": "2026-01-01T00:00:00Z"]
                ]
            ]
        ]
    }
}

/// Holds every thread that arrives until `count` of them have, then lets them all go at once.
private final class Barrier: @unchecked Sendable {
    private let condition = NSCondition()
    private let count: Int
    private var arrived = 0

    init(count: Int) {
        self.count = count
    }

    func arriveAndWait() {
        condition.lock()
        defer { condition.unlock() }
        arrived += 1
        if arrived == count {
            condition.broadcast()
        } else {
            while arrived < count {
                condition.wait()
            }
        }
    }
}
