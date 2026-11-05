import Foundation
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsServer
@testable import PocketCastsUtils
import XCTest

/// The full sync adds each of the user's podcasts, then saves its synced settings and the sync info of its
/// episodes. These tests answer the cache server and the API at the URL protocol level, so the podcast goes
/// through the same queues as in the app. They need the app's keychain for the sync token.
final class FullSyncPodcastImportTests: XCTestCase {
    private let lastSyncAt = "2026-11-05T10:00:00Z"
    private let featureFlagMock = FeatureFlagMock()
    private var originalDataManager: DataManager!
    private var databasePath: String!
    private var dataManager: DataManager!
    private var podcastUuid: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        ServerSettings.syncingV2Token = "token"

        originalDataManager = DataManager.shared
        databasePath = NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite")
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: databasePath)))
        DataManager.shared = dataManager

        podcastUuid = UUID().uuidString.lowercased()
        FullSyncURLProtocol.reset(podcastUuid: podcastUuid)
        URLProtocol.registerClass(FullSyncURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(FullSyncURLProtocol.self)
        KeychainHelper.removeKey(ServerConstants.Values.syncingV2TokenKey)
        featureFlagMock.reset()
        DataManager.shared = originalDataManager
        super.tearDown()
    }

    func testSavesTheSyncInfoWhenTheEpisodeStateIsRetrievedOnTheImportThread() throws {
        featureFlagMock.set(.fullSyncEpisodeStateOffInsertQueue, value: true)

        try processPodcastAndCheckTheSyncInfo()
    }

    func testSavesTheSyncInfoWhenTheEpisodeStateIsRetrievedOnTheInsertQueue() throws {
        featureFlagMock.set(.fullSyncEpisodeStateOffInsertQueue, value: false)

        try processPodcastAndCheckTheSyncInfo()
    }

    func testSavesNothingWhenThePodcastCannotBeAdded() throws {
        featureFlagMock.set(.fullSyncEpisodeStateOffInsertQueue, value: true)
        FullSyncURLProtocol.podcastStatusCode = 404

        processPodcast()

        XCTAssertNil(try savedPodcast())
        XCTAssertNil(dataManager.findEpisode(uuid: "\(podcastUuid!)-1"))
    }

    // MARK: - Helpers

    private func processPodcastAndCheckTheSyncInfo() throws {
        processPodcast()

        let podcast = try XCTUnwrap(savedPodcast())
        XCTAssertEqual(podcast.startFrom, 30)
        XCTAssertEqual(podcast.skipLast, 15)
        XCTAssertEqual(podcast.sortOrder, 7)
        XCTAssertEqual(podcast.syncStatus, SyncStatus.synced.rawValue)
        XCTAssertEqual(podcast.fullSyncLastSyncAt, lastSyncAt)

        let played = try XCTUnwrap(dataManager.findEpisode(uuid: "\(podcastUuid!)-1"))
        XCTAssertEqual(played.podcast_id, podcast.id)
        XCTAssertEqual(played.playingStatus, PlayingStatus.completed.rawValue)
        XCTAssertEqual(played.playedUpTo, 540)
        XCTAssertTrue(played.archived)
        XCTAssertTrue(played.keepEpisode)

        let unplayed = try XCTUnwrap(dataManager.findEpisode(uuid: "\(podcastUuid!)-2"))
        XCTAssertEqual(unplayed.playingStatus, PlayingStatus.notPlayed.rawValue)
        XCTAssertFalse(unplayed.archived)

        XCTAssertEqual(FullSyncURLProtocol.episodeStateRequestCount, 1)
    }

    /// The podcast as saved in the database. `dataManager` caches podcasts, and the sync changes the cached
    /// copy before it saves it.
    private func savedPodcast() throws -> Podcast? {
        try DataManager(dbQueue: GRDBQueue(dbPool: DatabasePool(path: databasePath))).findPodcast(uuid: podcastUuid)
    }

    /// Runs off the main thread, like the full sync's import queue does.
    private func processPodcast() {
        var podcast = PodcastSyncInfo()
        podcast.uuid = podcastUuid
        podcast.autoStartFrom = 30
        podcast.autoSkipLast = 15
        podcast.sortPosition = 7

        let processed = expectation(description: "The podcast is processed")
        let syncTask = SyncTask(dataManager: dataManager)
        let lastSyncAt = lastSyncAt
        DispatchQueue.global().async {
            syncTask.processPodcast(podcast, lastSyncAt: lastSyncAt)
            processed.fulfill()
        }
        wait(for: [processed], timeout: 60)
    }
}

/// Answers the podcast request with two episodes, and the episode state request with the first one played,
/// archived and starred. Everything else gets a 404.
private final class FullSyncURLProtocol: URLProtocol {
    nonisolated(unsafe) static var podcastUuid = ""
    nonisolated(unsafe) static var podcastStatusCode = 200
    private static let lock = NSLock()
    nonisolated(unsafe) private static var requestCount = 0

    static var episodeStateRequestCount: Int {
        lock.withLock { requestCount }
    }

    static func reset(podcastUuid: String) {
        self.podcastUuid = podcastUuid
        podcastStatusCode = 200
        lock.withLock { requestCount = 0 }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }

        let statusCode: Int
        let data: Data
        if url.path.hasSuffix("mobile/podcast/full/\(Self.podcastUuid)") {
            statusCode = Self.podcastStatusCode
            data = Self.podcastJson()
        } else if url.path.hasSuffix("user/podcast/episodes") {
            Self.lock.withLock { Self.requestCount += 1 }
            statusCode = 200
            data = Self.episodeState()
        } else {
            statusCode = 404
            data = Data()
        }

        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func podcastJson() -> Data {
        let episodes: [[String: Any]] = (1...2).map { number in
            [
                "uuid": "\(podcastUuid)-\(number)",
                "title": "Episode \(number)",
                "url": "https://pocketcasts.invalid/\(podcastUuid)/\(number).mp3",
                "file_type": "audio/mp3",
                "file_size": 1_000_000,
                "duration": 600,
                "published": "2026-01-0\(number)T10:00:00Z"
            ]
        }
        let podcast: [String: Any] = [
            "uuid": podcastUuid,
            "title": "Full Sync Podcast",
            "author": "Pocket Casts",
            "episodes": episodes
        ]

        return try! JSONSerialization.data(withJSONObject: ["podcast": podcast])
    }

    private static func episodeState() -> Data {
        var played = Api_EpisodeSyncResponse()
        played.uuid = "\(podcastUuid)-1"
        played.playingStatus = PlayingStatus.completed.rawValue
        played.playedUpTo = 540
        played.duration = 600
        played.isDeleted = true
        played.starred = true

        var response = Api_SyncEpisodesResponse()
        response.episodes = [played]

        return try! response.serializedData()
    }
}
