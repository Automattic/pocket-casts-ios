import XCTest
import FMDB
import PocketCastsUtils
import SQLite3
@testable import PocketCastsDataModel

final class AutoAddCandidatesDataManagerTests: XCTestCase {

    private var overriddenFlags = [FeatureFlag: Bool]()

    private func override(flag: FeatureFlag, value: Bool) throws {
        overriddenFlags[flag] = flag.enabled
        try FeatureFlagOverrideStore().override(flag, withValue: value)
    }

    private func reset(flag: FeatureFlag) throws {
        if let oldValue = overriddenFlags[flag] {
            try FeatureFlagOverrideStore().override(flag, withValue: oldValue)
        }
    }

    private func setupDatabase() throws -> DataManager {
        let dbPath = (DataManager.pathToDbFolder() as NSString).appendingPathComponent("podcast_testDB.sqlite3")
        try FileManager.default.removeItem(atPath: dbPath)
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FILEPROTECTION_NONE
        let dbQueue = try XCTUnwrap(FMDatabaseQueue(path: dbPath, flags: flags))
        return DataManager(dbQueue: dbQueue)
    }

    func testSyncableUpNextSetting() throws {
        try override(flag: .settingsSync, value: true)

        let dataManager = try setupDatabase()

        let podcast = Podcast()
        podcast.uuid = "1234"
        podcast.addedDate = Date()
        podcast.settings.addToUpNext = true
        podcast.settings.addToUpNextPosition = .top

        let episode = Episode()
        episode.uuid = "1234"
        episode.addedDate = Date()
        episode.podcastUuid = podcast.uuid

        dataManager.save(podcast: podcast)
        dataManager.save(episode: episode)
        dataManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)

        let candidates = dataManager.autoAddCandidates.candidates()

        XCTAssertTrue(candidates.contains(where: { $0.episodeUuid == episode.uuid }), "Episode should appear in Up Next candidates")

        try reset(flag: .settingsSync)
    }

    func testOldUpNextSetting() throws {
        try override(flag: .settingsSync, value: false)

        let dataManager = try setupDatabase()

        let podcast = Podcast()
        podcast.uuid = "1234"
        podcast.addedDate = Date()
        podcast.settings.addToUpNext = true
        podcast.settings.addToUpNextPosition = .top

        let episode = Episode()
        episode.uuid = "1234"
        episode.addedDate = Date()
        episode.podcastUuid = podcast.uuid

        dataManager.save(podcast: podcast)
        dataManager.save(episode: episode)
        dataManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)

        let candidates = dataManager.autoAddCandidates.candidates()

        XCTAssertTrue(candidates.contains(where: { $0.episodeUuid == episode.uuid }), "Episode should appear in Up Next candidates")

        try reset(flag: .settingsSync)
    }


}
