import Foundation
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsServer
@testable import PocketCastsUtils
import XCTest

/// The full sync adds each of the user's podcasts, then saves its synced settings and the state of its episodes.
/// These tests answer the cache server and the API at the URL protocol level, so the podcast goes through the
/// same queues as in the app. They need the app's keychain for the sync token.
final class FullSyncPodcastImportTests: XCTestCase {
    private let lastSyncAt = "2026-11-05T10:00:00Z"
    private var originalSyncToken: String?
    private var originalDataManager: DataManager!
    private var directory: URL!
    private var databasePath: String!
    private var dataManager: DataManager!
    private var podcastUuid: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalSyncToken = ServerSettings.syncingV2Token
        ServerSettings.syncingV2Token = "token"

        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        databasePath = directory.appendingPathComponent("podcasts.sqlite").path
        originalDataManager = DataManager.shared
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: databasePath)))
        DataManager.shared = dataManager

        podcastUuid = UUID().uuidString.lowercased()
        FullSyncURLProtocol.reset(podcastUuid: podcastUuid)
        URLProtocol.registerClass(FullSyncURLProtocol.self)
    }

    override func tearDownWithError() throws {
        URLProtocol.unregisterClass(FullSyncURLProtocol.self)
        try FeatureFlagOverrideStore().override(FeatureFlag.fullSyncEpisodeStateInParallel, withValue: FeatureFlag.fullSyncEpisodeStateInParallel.default)
        ServerSettings.syncingV2Token = originalSyncToken
        DataManager.shared = originalDataManager
        dataManager = nil
        try FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    // MARK: - Episode state requested with the podcast

    func testSavesTheSyncInfoWhenTheEpisodeStateIsRequestedWithThePodcast() throws {
        try processPodcast(episodeStateInParallel: true)

        try checkTheSyncInfo()
        XCTAssertEqual(FullSyncURLProtocol.episodeStateRequestCount, 1)
    }

    func testRequestsTheEpisodeStateBeforeThePodcastArrives() throws {
        FullSyncURLProtocol.podcastDelay = 0.5

        try processPodcast(episodeStateInParallel: true)

        XCTAssertEqual(FullSyncURLProtocol.episodeStateRequestsBeforeThePodcastResponse, 1)
        try checkTheSyncInfo()
    }

    func testRequestsTheEpisodeStateAfterThePodcastArrivesWhenTheFlagIsOff() throws {
        FullSyncURLProtocol.podcastDelay = 0.5

        try processPodcast(episodeStateInParallel: false)

        XCTAssertEqual(FullSyncURLProtocol.episodeStateRequestsBeforeThePodcastResponse, 0)
        try checkTheSyncInfo()
    }

    func testSavesThePodcastWhenTheEpisodeStateCannotBeRetrievedWithThePodcast() throws {
        FullSyncURLProtocol.episodeStateStatusCode = 500

        try processPodcast(episodeStateInParallel: true)

        try checkTheSyncInfoWithoutTheEpisodeState()
    }

    func testSavesNothingWhenThePodcastCannotBeLoadedWithItsEpisodeState() throws {
        FullSyncURLProtocol.podcastStatusCode = 404

        try processPodcast(episodeStateInParallel: true)

        XCTAssertNil(try savedPodcast())
    }

    // MARK: - Episode state requested after adding the podcast

    func testSavesTheSyncInfoWhenTheEpisodeStateIsRequestedAfterAddingThePodcast() throws {
        try processPodcast(episodeStateInParallel: false)

        try checkTheSyncInfo()
        XCTAssertEqual(FullSyncURLProtocol.episodeStateRequestCount, 1)
    }

    func testSavesNothingWhenThePodcastCannotBeLoadedBeforeItsEpisodeState() throws {
        FullSyncURLProtocol.podcastStatusCode = 404

        try processPodcast(episodeStateInParallel: false)

        XCTAssertNil(try savedPodcast())
        XCTAssertEqual(FullSyncURLProtocol.episodeStateRequestCount, 0)
    }

    // MARK: - Helpers

    private func checkTheSyncInfo() throws {
        let podcast = try checkThePodcastSyncInfo()

        let played = try XCTUnwrap(savedEpisode(number: 1))
        XCTAssertEqual(played.podcast_id, podcast.id)
        XCTAssertEqual(played.playingStatus, PlayingStatus.completed.rawValue)
        XCTAssertEqual(played.playedUpTo, 540)
        XCTAssertTrue(played.archived)
        XCTAssertTrue(played.keepEpisode)

        let unplayed = try XCTUnwrap(savedEpisode(number: 2))
        XCTAssertEqual(unplayed.playingStatus, PlayingStatus.notPlayed.rawValue)
        XCTAssertFalse(unplayed.archived)
    }

    private func checkTheSyncInfoWithoutTheEpisodeState() throws {
        try checkThePodcastSyncInfo()

        for number in 1...2 {
            let episode = try XCTUnwrap(savedEpisode(number: number))
            XCTAssertEqual(episode.playingStatus, PlayingStatus.notPlayed.rawValue)
            XCTAssertFalse(episode.archived)
            XCTAssertFalse(episode.keepEpisode)
        }
    }

    @discardableResult
    private func checkThePodcastSyncInfo() throws -> Podcast {
        let podcast = try XCTUnwrap(savedPodcast())
        XCTAssertEqual(podcast.startFrom, 30)
        XCTAssertEqual(podcast.skipLast, 15)
        XCTAssertEqual(podcast.sortOrder, 7)
        XCTAssertEqual(podcast.syncStatus, SyncStatus.synced.rawValue)
        XCTAssertEqual(podcast.fullSyncLastSyncAt, lastSyncAt)
        return podcast
    }

    /// The podcast as saved in the database. `dataManager` caches podcasts, and the sync changes the cached
    /// copy before it saves it.
    private func savedPodcast() throws -> Podcast? {
        try savedDataManager().findPodcast(uuid: podcastUuid)
    }

    private func savedEpisode(number: Int) throws -> Episode? {
        try savedDataManager().findEpisode(uuid: "\(podcastUuid!)-\(number)")
    }

    private func savedDataManager() throws -> DataManager {
        DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: databasePath)))
    }

    /// Runs off the main thread, like the full sync's import queue does.
    private func processPodcast(episodeStateInParallel: Bool) throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.fullSyncEpisodeStateInParallel, withValue: episodeStateInParallel)

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

/// Answers the test podcast's request with two episodes, and its episode state request with the first one
/// played, archived and starred. Leaves every other request alone.
private final class FullSyncURLProtocol: URLProtocol {
    nonisolated(unsafe) static var podcastUuid = ""
    nonisolated(unsafe) static var podcastStatusCode = 200
    nonisolated(unsafe) static var episodeStateStatusCode = 200
    nonisolated(unsafe) static var podcastDelay: TimeInterval = 0
    nonisolated(unsafe) private(set) static var episodeStateRequestsBeforeThePodcastResponse: Int?
    private static let lock = NSLock()
    nonisolated(unsafe) private static var requestCount = 0

    static var episodeStateRequestCount: Int {
        lock.withLock { requestCount }
    }

    static func reset(podcastUuid: String) {
        self.podcastUuid = podcastUuid
        podcastStatusCode = 200
        episodeStateStatusCode = 200
        podcastDelay = 0
        episodeStateRequestsBeforeThePodcastResponse = nil
        lock.withLock { requestCount = 0 }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }

        return isPodcastRequest(url) || isEpisodeStateRequest(url)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }

        if Self.isPodcastRequest(url) {
            DispatchQueue.global().asyncAfter(deadline: .now() + Self.podcastDelay) {
                Self.episodeStateRequestsBeforeThePodcastResponse = Self.episodeStateRequestCount
                self.respond(statusCode: Self.podcastStatusCode, data: Self.podcastJson())
            }
        } else if Self.requestedUuid(request) == Self.podcastUuid {
            Self.lock.withLock { Self.requestCount += 1 }
            let statusCode = Self.episodeStateStatusCode
            respond(statusCode: statusCode, data: statusCode == 200 ? Self.episodeState() : Data())
        } else {
            respond(statusCode: 404, data: Data())
        }
    }

    override func stopLoading() {}

    private func respond(statusCode: Int, data: Data) {
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else { return }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    private static func isPodcastRequest(_ url: URL) -> Bool {
        url.path.hasSuffix("mobile/podcast/full/\(podcastUuid)")
    }

    private static func isEpisodeStateRequest(_ url: URL) -> Bool {
        url.host == URL(string: ServerConstants.Urls.api())?.host && url.path.hasSuffix("user/podcast/episodes")
    }

    /// URLSession hands the body to URL protocols as a stream.
    private static func requestedUuid(_ request: URLRequest) -> String? {
        guard let stream = request.httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            body.append(buffer, count: count)
        }

        return try? Api_UuidRequest(serializedBytes: body).uuid
    }

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
