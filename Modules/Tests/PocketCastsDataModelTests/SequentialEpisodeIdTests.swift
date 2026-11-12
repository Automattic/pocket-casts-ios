import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class SequentialEpisodeIdTests: DataManagerTestCase {
    private var userDefaultsSuiteName = ""
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        userDefaultsSuiteName = "SequentialEpisodeIdTests-\(UUID().uuidString)"
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsSuiteName))
    }

    override func tearDownWithError() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: true)
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        try super.tearDownWithError()
    }

    // MARK: - Allocation

    func testNewEpisodesGetTheIdsAfterTheLargestId() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let existing = self.makeEpisode(podcast: podcast)
            existing.id = 5_000_000_000_000_000_000
            dataManager.save(episode: existing)

            let batch = (0..<3).map { _ in self.makeEpisode(podcast: podcast) }
            dataManager.bulkSave(episodes: batch)
            let single = self.makeEpisode(podcast: podcast)
            dataManager.save(episode: single)
            let missing = (0..<2).map { _ in self.makeEpisode(podcast: podcast) }
            dataManager.insertMissing(episodes: missing)

            let episodes = batch + [single] + missing
            XCTAssertEqual(episodes.map(\.id), (1...6).map { 5_000_000_000_000_000_000 + $0 })
            for episode in episodes {
                XCTAssertEqual(dataManager.findEpisode(uuid: episode.uuid)?.id, episode.id)
            }
        }
    }

    func testEpisodesInAnEmptyTableStartAtOne() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episodes = (0..<3).map { _ in self.makeEpisode(podcast: podcast) }
            dataManager.bulkSave(episodes: episodes)

            XCTAssertEqual(episodes.map(\.id), [1, 2, 3])
        }
    }

    func testSavingAnExistingEpisodeKeepsItsId() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.makeEpisode(podcast: podcast)
            dataManager.save(episode: episode)
            let id = episode.id

            episode.title = "Updated"
            dataManager.save(episode: episode)
            dataManager.bulkSave(episodes: [episode])

            XCTAssertEqual(episode.id, id)
            XCTAssertEqual(dataManager.findEpisode(uuid: episode.uuid)?.id, id)
            XCTAssertEqual(dataManager.findEpisode(uuid: episode.uuid)?.title, "Updated")
            XCTAssertEqual(self.episodeCount(dataManager), 1)
        }
    }

    // MARK: - Deleted IDs

    func testNewEpisodeDoesNotReuseTheIdOfADeletedEpisode() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let kept = self.makeEpisode(podcast: podcast)
            let deleted = self.makeEpisode(podcast: podcast)
            dataManager.bulkSave(episodes: [kept, deleted])
            dataManager.delete(episodeUuid: deleted.uuid)

            let new = self.makeEpisode(podcast: podcast)
            dataManager.save(episode: new)

            XCTAssertGreaterThan(new.id, deleted.id)
        }
    }

    func testNewEpisodeDoesNotReuseTheIdOfAnEpisodeSavedBeforeLaunchAndDeletedAfter() throws {
        let path = try makeDatabasePath()
        let firstLaunch = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: firstLaunch)
        let episodes = (0..<3).map { _ in makeEpisode(podcast: podcast) }
        firstLaunch.bulkSave(episodes: episodes)

        let secondLaunch = try makeDataManager(path: path)
        let stale = try XCTUnwrap(secondLaunch.findEpisode(uuid: episodes[2].uuid))
        secondLaunch.delete(episodeUuid: stale.uuid)

        let new = makeEpisode(podcast: podcast)
        secondLaunch.save(episode: new)

        XCTAssertGreaterThan(new.id, stale.id)
    }

    func testSavingAStaleCopyOfADeletedEpisodeDoesNotOverwriteANewEpisode() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let kept = self.makeEpisode(podcast: podcast)
            let stale = self.makeEpisode(podcast: podcast)
            dataManager.bulkSave(episodes: [kept, stale])
            dataManager.delete(episodeUuid: stale.uuid)

            let new = self.makeEpisode(podcast: podcast)
            dataManager.save(episode: new)
            dataManager.save(episode: stale)

            XCTAssertEqual(dataManager.findEpisode(uuid: new.uuid)?.id, new.id)
            XCTAssertEqual(dataManager.findEpisode(uuid: stale.uuid)?.id, stale.id)
            XCTAssertEqual(self.episodeCount(dataManager), 3)
        }
    }

    // MARK: - Mixed and full ranges

    func testNewEpisodesFollowTheLargestOfMixedRandomAndSequentialIds() throws {
        let path = try makeDatabasePath()
        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: false)
        let flagOff = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: flagOff)
        let random = (0..<50).map { _ in makeEpisode(podcast: podcast) }
        flagOff.bulkSave(episodes: random)

        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: true)
        let flagOn = try makeDataManager(path: path)
        let sequential = (0..<3).map { _ in makeEpisode(podcast: podcast) }
        flagOn.bulkSave(episodes: sequential)

        let largestRandomId = try XCTUnwrap(random.map(\.id).max())
        XCTAssertEqual(sequential.map(\.id), (1...3).map { largestRandomId + $0 })
        XCTAssertEqual(episodeCount(flagOn), 53)
    }

    func testRandomIdsSavedByAnOlderVersionDoNotCollideWithSequentialIds() throws {
        let path = try makeDatabasePath()
        let firstLaunch = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: firstLaunch)
        let sequential = (0..<100).map { _ in makeEpisode(podcast: podcast) }
        firstLaunch.bulkSave(episodes: sequential)

        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: false)
        let flagOff = try makeDataManager(path: path)
        let random = (0..<100).map { _ in makeEpisode(podcast: podcast) }
        flagOff.bulkSave(episodes: random)

        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: true)
        let flagOn = try makeDataManager(path: path)
        let next = makeEpisode(podcast: podcast)
        flagOn.save(episode: next)

        XCTAssertEqual(next.id, try XCTUnwrap(random.map(\.id).max()) + 1)
        XCTAssertEqual(Set((sequential + random + [next]).map(\.id)).count, 201)
        XCTAssertEqual(episodeCount(flagOn), 201)
    }

    func testNewEpisodesUseTheLastIdsBeforeInt64Max() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let existing = self.makeEpisode(podcast: podcast)
            existing.id = Int64.max - 2
            dataManager.save(episode: existing)

            let episodes = (0..<3).map { _ in self.makeEpisode(podcast: podcast) }
            dataManager.bulkSave(episodes: episodes)

            XCTAssertEqual(episodes[0].id, Int64.max - 1)
            XCTAssertEqual(episodes[1].id, Int64.max)
            XCTAssertGreaterThan(episodes[2].id, 0)
            XCTAssertLessThan(episodes[2].id, Int64.max)
            for episode in episodes {
                XCTAssertEqual(dataManager.findEpisode(uuid: episode.uuid)?.id, episode.id)
            }
        }
    }

    func testNewEpisodeGetsARandomIdWhenTheLargestIdIsInt64Max() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let existing = self.makeEpisode(podcast: podcast)
            existing.id = Int64.max
            dataManager.save(episode: existing)

            let new = self.makeEpisode(podcast: podcast)
            dataManager.save(episode: new)

            XCTAssertGreaterThan(new.id, 0)
            XCTAssertLessThan(new.id, Int64.max)
            XCTAssertEqual(dataManager.findEpisode(uuid: new.uuid)?.id, new.id)
            XCTAssertEqual(dataManager.findEpisode(uuid: existing.uuid)?.id, Int64.max)
        }
    }

    // MARK: - New installs

    func testNewEpisodesGetRandomIdsInADatabaseCreatedBeforeTheUpdate() throws {
        let path = try makeDatabasePath()
        let olderVersion = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: olderVersion)
        let existing = makeEpisode(podcast: podcast)
        existing.id = 1_000
        olderVersion.save(episode: existing)
        userDefaults.removeObject(forKey: "SequentialEpisodeIds")

        let update = try makeDataManager(path: path)
        let episodes = (0..<20).map { _ in makeEpisode(podcast: podcast) }
        update.bulkSave(episodes: episodes)
        let missing = (0..<20).map { _ in makeEpisode(podcast: podcast) }
        update.insertMissing(episodes: missing)

        let ids = (episodes + missing).map(\.id)
        XCTAssertEqual(Set(ids).count, 40)
        XCTAssertTrue(ids.allSatisfy { $0 > 0 })
        XCTAssertFalse(ids.contains(1_001))
        XCTAssertNotEqual(ids, ids.sorted())
        XCTAssertEqual(episodeCount(update), 41)
    }

    func testDatabaseCreatedByANewInstallKeepsSequentialIdsAfterARelaunch() throws {
        let path = try makeDatabasePath()
        let firstLaunch = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: firstLaunch)
        let episodes = (0..<3).map { _ in makeEpisode(podcast: podcast) }
        firstLaunch.bulkSave(episodes: episodes)

        let secondLaunch = try makeDataManager(path: path)
        let new = makeEpisode(podcast: podcast)
        secondLaunch.save(episode: new)

        XCTAssertEqual(new.id, episodes[2].id + 1)
    }

    // MARK: - Feature flag

    func testTurningTheFlagOffTakesEffectOnTheNextLaunch() throws {
        let path = try makeDatabasePath()
        let firstLaunch = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: firstLaunch)
        let first = makeEpisode(podcast: podcast)
        firstLaunch.save(episode: first)

        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: false)
        let sameLaunch = makeEpisode(podcast: podcast)
        firstLaunch.save(episode: sameLaunch)
        XCTAssertEqual(sameLaunch.id, first.id + 1)

        let secondLaunch = try makeDataManager(path: path)
        let nextLaunch = (0..<20).map { _ in makeEpisode(podcast: podcast) }
        secondLaunch.bulkSave(episodes: nextLaunch)
        let ids = nextLaunch.map(\.id)
        XCTAssertFalse(ids.contains(sameLaunch.id + 1))
        XCTAssertNotEqual(ids, ids.sorted())
    }

    func testNewEpisodesGetRandomIdsWhenTheFlagIsOff() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.sequentialEpisodeIds, withValue: false)

        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let existing = self.makeEpisode(podcast: podcast)
            existing.id = 1_000
            dataManager.save(episode: existing)

            let episodes = (0..<20).map { _ in self.makeEpisode(podcast: podcast) }
            dataManager.bulkSave(episodes: episodes)
            let missing = (0..<20).map { _ in self.makeEpisode(podcast: podcast) }
            dataManager.insertMissing(episodes: missing)

            let ids = (episodes + missing).map(\.id)
            XCTAssertEqual(Set(ids).count, 40)
            XCTAssertTrue(ids.allSatisfy { $0 > 0 })
            XCTAssertFalse(ids.contains(1_001))
            XCTAssertNotEqual(ids, ids.sorted())
            XCTAssertEqual(self.episodeCount(dataManager), 41)
        }
    }

    // MARK: - Concurrency

    func testConcurrentWritersGetUniqueIds() throws {
        try runWithNewDatabase { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let existing = self.makeEpisode(podcast: podcast)
            existing.id = 7_000_000_000_000_000_000
            dataManager.save(episode: existing)

            let writers = 24
            let saved = self.saveConcurrently(writers: writers, podcast: podcast, dataManagers: [dataManager])

            let ids = saved.map(\.id)
            XCTAssertEqual(ids.count, writers * 13)
            XCTAssertEqual(Set(ids).count, ids.count)
            XCTAssertEqual(ids.sorted(), (1...ids.count).map { 7_000_000_000_000_000_000 + Int64($0) })
            XCTAssertEqual(self.episodeCount(dataManager), ids.count + 1)
            for episode in saved {
                XCTAssertEqual(dataManager.findEpisode(uuid: episode.uuid)?.id, episode.id)
            }
        }
    }

    func testTwoDatabasePoolsOnTheSameFileGetUniqueIds() throws {
        let path = try makeDatabasePath()
        let first = try makeDataManager(path: path)
        let podcast = createTestPodcast(dataManager: first)
        let existing = makeEpisode(podcast: podcast)
        first.save(episode: existing)
        let second = try makeDataManager(path: path)

        let writers = 16
        let saved = saveConcurrently(writers: writers, podcast: podcast, dataManagers: [first, second])

        let ids = saved.map(\.id).sorted()
        XCTAssertEqual(ids.count, writers * 13)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(ids, (1...ids.count).map { existing.id + Int64($0) })
        XCTAssertEqual(episodeCount(first), ids.count + 1)
        XCTAssertEqual(episodeCount(second), ids.count + 1)
        for episode in saved {
            XCTAssertEqual(first.findEpisode(uuid: episode.uuid)?.id, episode.id)
        }
    }

    // MARK: - Helpers

    private func runWithNewDatabase(_ testBlock: (DataManager) throws -> Void) throws {
        let dbPool = try XCTUnwrap(DatabasePool.newTestDatabase())
        try testBlock(DataManager(dbQueue: GRDBQueue(dbPool: dbPool), userDefaults: userDefaults))
    }

    /// Each writer saves 13 new episodes: one with `save`, five with `bulkSave`, and seven with `insertMissing`
    private func saveConcurrently(writers: Int, podcast: Podcast, dataManagers: [DataManager]) -> [Episode] {
        let lock = NSLock()
        var saved = [Episode]()
        DispatchQueue.concurrentPerform(iterations: writers) { index in
            let dataManager = dataManagers[index % dataManagers.count]
            let single = makeEpisode(podcast: podcast)
            let batch = (0..<5).map { _ in makeEpisode(podcast: podcast) }
            let missing = (0..<7).map { _ in makeEpisode(podcast: podcast) }
            dataManager.save(episode: single)
            dataManager.bulkSave(episodes: batch)
            dataManager.insertMissing(episodes: missing)
            lock.withLock { saved += [single] + batch + missing }
        }
        return saved
    }

    private func makeEpisode(podcast: Podcast) -> Episode {
        let episode = Episode()
        episode.uuid = UUID().uuidString
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.addedDate = Date()
        episode.publishedDate = Date()
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        return episode
    }

    private func episodeCount(_ dataManager: DataManager) -> Int {
        dataManager.count(query: "SELECT COUNT(*) FROM \(DataManager.episodeTableName)", values: nil)
    }

    private func makeDatabasePath() throws -> String {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SequentialEpisodeIdTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
        return folder.appendingPathComponent("podcast_newDB.sqlite3").path
    }

    private func makeDataManager(path: String) throws -> DataManager {
        var config = Configuration()
        config.busyMode = .timeout(10)
        return DataManager(dbQueue: GRDBQueue(dbPool: try DatabasePool(path: path, configuration: config)), userDefaults: userDefaults)
    }
}
