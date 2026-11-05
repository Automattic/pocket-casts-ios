@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import GRDB
import XCTest

/// `addFromJson` saves a podcast that isn't in the database yet together with the episodes in its JSON.
final class ServerPodcastManagerAddFromJsonTests: XCTestCase {
    private let featureFlagMock = FeatureFlagMock()
    private var originalDataManager: DataManager!
    private var dataManager: DataManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalDataManager = DataManager.shared
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite"))))
        DataManager.shared = dataManager

        URLProtocol.registerClass(OfflineURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(OfflineURLProtocol.self)
        featureFlagMock.reset()
        DataManager.shared = originalDataManager
        super.tearDown()
    }

    func testSavesTheEpisodesOfANewPodcastWithItsId() throws {
        for enabled in [true, false] {
            featureFlagMock.set(.parseEpisodesBeforeInsertQueue, value: enabled)
            let uuid = UUID().uuidString.lowercased()

            XCTAssertTrue(add(Self.podcastInfo(uuid: uuid, episodeCount: 3)))

            let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: uuid, includeUnsubscribed: true))
            let episodes = dataManager.allEpisodes(forPodcastId: podcast.id)
            XCTAssertEqual(Set(episodes.map(\.uuid)), ["\(uuid)-1", "\(uuid)-2", "\(uuid)-3"], "parseEpisodesBeforeInsertQueue: \(enabled)")
            XCTAssertTrue(episodes.allSatisfy { $0.podcastUuid == uuid })
            XCTAssertEqual(podcast.latestEpisodeUuid, "\(uuid)-3")

            let episode = try XCTUnwrap(dataManager.findEpisode(uuid: "\(uuid)-1"))
            XCTAssertEqual(episode.podcast_id, podcast.id)
            XCTAssertEqual(episode.title, "Episode 1")
            XCTAssertEqual(episode.downloadUrl, "https://pocketcasts.invalid/\(uuid)/1.mp3")
            XCTAssertEqual(episode.publishedDate, Date(timeIntervalSince1970: 1_767_261_600))
            XCTAssertEqual(episode.duration, 600)
            XCTAssertEqual(episode.sizeInBytes, 1_000_000)
            XCTAssertEqual(episode.playingStatus, PlayingStatus.notPlayed.rawValue)
        }
    }

    func testSubscribesToAPodcastThatIsAlreadySavedWithoutAddingItsEpisodes() throws {
        featureFlagMock.set(.parseEpisodesBeforeInsertQueue, value: true)
        let uuid = UUID().uuidString.lowercased()
        let existing = Podcast()
        existing.uuid = uuid
        existing.title = "Existing"
        existing.subscribed = 0
        dataManager.save(podcast: existing)

        XCTAssertTrue(add(Self.podcastInfo(uuid: uuid, episodeCount: 2), subscribe: true))

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: uuid))
        XCTAssertEqual(podcast.id, existing.id)
        XCTAssertTrue(dataManager.allEpisodes(forPodcastId: podcast.id).isEmpty)
    }

    func testDoesNotAddAPodcastWithoutEpisodes() {
        featureFlagMock.set(.parseEpisodesBeforeInsertQueue, value: true)
        let uuid = UUID().uuidString.lowercased()

        XCTAssertFalse(add(Self.podcastInfo(uuid: uuid, episodeCount: nil)))

        XCTAssertNil(dataManager.findPodcast(uuid: uuid, includeUnsubscribed: true))
    }

    func testSavesTheEpisodesOnceWhenTheSamePodcastIsAddedTwiceAtOnce() throws {
        featureFlagMock.set(.parseEpisodesBeforeInsertQueue, value: true)
        let uuid = UUID().uuidString.lowercased()
        let podcastInfo = Self.podcastInfo(uuid: uuid, episodeCount: 5)

        let added = expectation(description: "Both adds finish")
        added.expectedFulfillmentCount = 2
        for _ in 0..<2 {
            ServerPodcastManager.shared.addFromJson(podcastUuid: uuid, lastModified: nil, podcastInfo: podcastInfo, subscribe: false, autoDownloads: 0) { success in
                XCTAssertTrue(success)
                added.fulfill()
            }
        }
        wait(for: [added], timeout: 30)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: uuid, includeUnsubscribed: true))
        XCTAssertEqual(dataManager.count(query: "SELECT COUNT(*) FROM \(DataManager.podcastTableName) WHERE uuid = ?", values: [uuid]), 1)
        XCTAssertEqual(dataManager.count(query: "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcastUuid = ?", values: [uuid]), 5)
        XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).count, 5)
    }

    func testSavesEachPodcastWithItsOwnEpisodesWhenSeveralAreAddedAtOnce() throws {
        featureFlagMock.set(.parseEpisodesBeforeInsertQueue, value: true)
        let uuids = (0..<10).map { _ in UUID().uuidString.lowercased() }

        let added = expectation(description: "All podcasts are added")
        added.expectedFulfillmentCount = uuids.count
        DispatchQueue.concurrentPerform(iterations: uuids.count) { index in
            let uuid = uuids[index]
            ServerPodcastManager.shared.addFromJson(podcastUuid: uuid, lastModified: nil, podcastInfo: Self.podcastInfo(uuid: uuid, episodeCount: 20), subscribe: false, autoDownloads: 0) { success in
                XCTAssertTrue(success)
                added.fulfill()
            }
        }
        wait(for: [added], timeout: 30)

        for uuid in uuids {
            let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: uuid, includeUnsubscribed: true))
            let episodes = dataManager.allEpisodes(forPodcastId: podcast.id)
            XCTAssertEqual(episodes.count, 20)
            XCTAssertTrue(episodes.allSatisfy { $0.podcastUuid == uuid })
        }
    }

    // MARK: - Helpers

    private func add(_ podcastInfo: [String: Any], subscribe: Bool = false) -> Bool {
        let uuid = (podcastInfo["podcast"] as? [String: Any])?["uuid"] as? String ?? ""
        let added = expectation(description: "The add finishes")
        var result = false
        ServerPodcastManager.shared.addFromJson(podcastUuid: uuid, lastModified: nil, podcastInfo: podcastInfo, subscribe: subscribe, autoDownloads: 0) { success in
            result = success
            added.fulfill()
        }
        wait(for: [added], timeout: 30)

        return result
    }

    /// The JSON the cache server returns for a podcast, read with `JSONSerialization` as `CacheServerHandler` does.
    /// The first episode is published on 1 January 2026 at 10:00 UTC, and each one after it a day later.
    private static func podcastInfo(uuid: String, episodeCount: Int?) -> [String: Any] {
        var podcast: [String: Any] = ["uuid": uuid, "title": "Podcast \(uuid)", "author": "Pocket Casts"]
        if let episodeCount {
            podcast["episodes"] = (0..<episodeCount).map { index -> [String: Any] in
                [
                    "uuid": "\(uuid)-\(index + 1)",
                    "title": "Episode \(index + 1)",
                    "url": "https://pocketcasts.invalid/\(uuid)/\(index + 1).mp3",
                    "file_type": "audio/mp3",
                    "file_size": 1_000_000,
                    "duration": 600,
                    "published": String(format: "2026-01-%02dT10:00:00Z", index + 1)
                ]
            }
        }

        let data = try! JSONSerialization.data(withJSONObject: ["podcast": podcast])
        return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
}

/// Fails every request, so that loading an added podcast's metadata doesn't go to the network.
private final class OfflineURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}
