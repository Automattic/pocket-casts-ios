@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB
import SwiftProtobuf

final class SyncTaskTests_PodcastImport: XCTestCase {
    private var originalDataManager: DataManager!
    private var dataManager: PodcastCapturingDataManager!
    private var serverPodcastManager: CapturingServerPodcastManager!
    private var syncTask: SyncTask!

    override func setUpWithError() throws {
        try super.setUpWithError()

        originalDataManager = DataManager.sharedManager
        dataManager = PodcastCapturingDataManager()
        DataManager.sharedManager = dataManager

        serverPodcastManager = CapturingServerPodcastManager()
        syncTask = SyncTask(dataManager: dataManager, serverPodcastManager: serverPodcastManager)
    }

    override func tearDownWithError() throws {
        DataManager.sharedManager = originalDataManager
        syncTask = nil
        serverPodcastManager = nil
        dataManager = nil
        originalDataManager = nil

        try super.tearDownWithError()
    }

    func testDoesNotReSubscribeMissingPodcastWhenServerMarksUnsubscribed() {
        let uuid = "pod-missing"

        var podcast = Api_SyncUserPodcast()
        podcast.uuid = uuid
        podcast.subscribed = Self.boolValue(false)

        var record = Api_Record()
        record.podcast = podcast

        var response = Api_SyncUpdateResponse()
        response.records = [record]

        syncTask.processServerData(response: response)

        XCTAssertTrue(serverPodcastManager.addFromUuidCalls.isEmpty)
        XCTAssertNil(DataManager.sharedManager.findPodcast(uuid: uuid, includeUnsubscribed: true))
    }
}

private final class CapturingServerPodcastManager: ServerPodcastManaging {
    private(set) var addFromUuidCalls: [(uuid: String, subscribe: Bool, autoDownloads: Int)] = []

    func addFromUuid(podcastUuid: String, subscribe: Bool, autoDownloads: Int, completion: ((Bool) -> Void)?) {
        addFromUuidCalls.append((podcastUuid, subscribe, autoDownloads))
        completion?(false)
    }

    func addMissingPodcast(episodeUuid: String, podcastUuid: String) {}

    func addMissingEpisode(episodeUuid: String, podcastUuid: String) -> Episode? {
        nil
    }

    func addMissingPodcastAndEpisode(episodeUuid: String, podcastUuid: String, shouldUpdateEpisode: Bool, completion: ((Episode?) -> Void)?) {
        completion?(nil)
    }
}

private final class PodcastCapturingDataManager: DataManager {
    private var storedPodcasts: [String: Podcast] = [:]

    init() {
        let dbPath = NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite")
        let pool = try! DatabasePool(path: dbPath)
        super.init(dbQueue: GRDBQueue(dbPool: pool, logger: DataManager.logger))
    }

    override func findPodcast(uuid: String, includeUnsubscribed: Bool = false) -> Podcast? {
        storedPodcasts[uuid]
    }

    override func save(podcast: Podcast) {
        storedPodcasts[podcast.uuid] = podcast
    }

    func storedPodcastCount() -> Int {
        storedPodcasts.count
    }

    override func markAllSynced(episodeIDs: [String]) {
        // no-op for tests
    }
}

private extension SyncTaskTests_PodcastImport {
    static func boolValue(_ value: Bool) -> SwiftProtobuf.Google_Protobuf_BoolValue {
        var bool = SwiftProtobuf.Google_Protobuf_BoolValue()
        bool.value = value
        return bool
    }
}
