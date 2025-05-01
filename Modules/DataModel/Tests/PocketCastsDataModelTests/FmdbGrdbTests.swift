import XCTest
import FMDB
import GRDB
@testable import PocketCastsUtils
import SQLite3
@testable import PocketCastsDataModel

final class FmdbGrdbTests: XCTestCase {
    private let featureFlagMock = FeatureFlagMock()

    lazy var isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    private func setupDataManagerWithFMDB() throws -> DataManager {
        DataManager(grdbEnabled: false, databaseFileName: "podcast_testDB.sqlite3")
    }

    private func setupDataManagerWithGRDB() throws -> DataManager {
        DataManager(grdbEnabled: true, databaseFileName: "podcast_testDB_GRDB.sqlite3")
    }

    // We have a check inside DataManager where the queue is closed
    // if GRDB feature flag is false.
    // Here we temporarily override this to prevent this behavior.
    private func grdbDatabaManager(dbPool: DatabasePool) -> DataManager {
        featureFlagMock.set(.grdb, value: true)
        let dataManager = DataManager(dbQueue: GRDBQueue(dbPool: dbPool))
        featureFlagMock.reset()
        return dataManager
    }

    func testGrdbFmdb() throws {
        // Create two podcasts, save them to FMDB and GRDB.
        // Then read them back from FMDB and GRDB and compare them.
        let fmdbDataManager = try setupDataManagerWithFMDB()
        let grdbDataManager = try setupDataManagerWithGRDB()

        let jsonString = Podcast.fixture
        let data = jsonString.data(using: .utf8)

        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]

        let podcastOne = Podcast.from(podcastJson: json!["podcast"] as! [String: Any], podcastInfo: [:], uuid: "b5363810-adfb-013d-1a6e-0acc26574db2", subscribe: true, autoDownloads: 0, lastModified: "2025-02-18 08:00:00.000", isoFormatter: isoFormatter)

        let podcastTwo = Podcast.from(podcastJson: json!["podcast"] as! [String: Any], podcastInfo: [:], uuid: "b5363810-adfb-013d-1a6e-0acc26574db2", subscribe: true, autoDownloads: 0, lastModified: "2025-02-18 08:00:00.000", isoFormatter: isoFormatter)

        fmdbDataManager.save(podcast: podcastOne)
        grdbDataManager.save(podcast: podcastTwo)

        let fmdbPodcast = fmdbDataManager.findPodcast(uuid: "b5363810-adfb-013d-1a6e-0acc26574db2")
        let grdbPodcast = grdbDataManager.findPodcast(uuid: "b5363810-adfb-013d-1a6e-0acc26574db2")

        XCTAssertTrue(fmdbPodcast!.isEqual(to: grdbPodcast!))

        // Create episodes, save them to FMDB and GRDB.
        // Then read them back from FMDB and GRDB and compare them.
        let jsonPodcast = json!["podcast"] as! [String: Any]
        let jsonEpisodes = jsonPodcast["episodes"] as! [[String: Any]]

        jsonEpisodes.forEach { jsonEpisode in
            let episodeUuid = jsonEpisode["uuid"]! as! String
            let episodeOne = Episode.from(episodeJson: jsonEpisode, podcastId: fmdbPodcast!.id, podcastUuid: fmdbPodcast!.uuid, isoFormatter: isoFormatter)
            let episodeTwo = Episode.from(episodeJson: jsonEpisode, podcastId: grdbPodcast!.id, podcastUuid: grdbPodcast!.uuid, isoFormatter: isoFormatter)

            fmdbDataManager.save(episode: episodeOne)
            grdbDataManager.save(episode: episodeTwo)

            let fmdbEpisode = fmdbDataManager.findEpisode(uuid: episodeUuid)
            let grdbEpisode = grdbDataManager.findEpisode(uuid: episodeUuid)

            XCTAssertTrue(fmdbEpisode!.isEqual(to: grdbEpisode!))
        }

        // Open the GRDB database with FMDB, and the FMDB database with GRDB.
        // Then read the podcasts and episodes back from FMDB and GRDB and compare them.
        // This ensures that the databases are compatible with each other.

        fmdbDataManager.close()
        grdbDataManager.close()
        try! DatabasePool.copyDatabase(toFile: "GRDB_copy.sqlite3")
        try! FMDatabaseQueue.copyDatabase(toFile: "FMDB_copy.sqlite3")

        let fmdbFromGrdbDataManager = DataManager(grdbEnabled: false, databaseFileName: "GRDB_copy.sqlite3")

        let grdbFromFmdbDataManager = DataManager(grdbEnabled: true, databaseFileName: "FMDB_copy.sqlite3")

        let fmdbPodcastReadFromGrdb = fmdbFromGrdbDataManager.findPodcast(uuid: "b5363810-adfb-013d-1a6e-0acc26574db2")
        let grdbPodcastReadFromFmdb = grdbFromFmdbDataManager.findPodcast(uuid: "b5363810-adfb-013d-1a6e-0acc26574db2")

        XCTAssertTrue(fmdbPodcastReadFromGrdb!.isEqual(to: grdbPodcastReadFromFmdb!))

        // Compare the episodes
        jsonEpisodes.forEach { jsonEpisode in
            let episodeUuid = jsonEpisode["uuid"]! as! String

            let fmdbEpisode = fmdbFromGrdbDataManager.findEpisode(uuid: episodeUuid)
            let grdbEpisode = grdbFromFmdbDataManager.findEpisode(uuid: episodeUuid)

            XCTAssertTrue(fmdbEpisode!.isEqual(to: grdbEpisode!))
        }
    }
}

extension NSObject {
    func isEqual(to other: Any) -> Bool {
        guard let other = other as? Self else { return false }

        let mirror1 = Mirror(reflecting: self)
        let mirror2 = Mirror(reflecting: other)

        guard mirror1.children.count == mirror2.children.count else { return false }

        for (child1, child2) in zip(mirror1.children, mirror2.children) {
            // Exclude fields that are dynamic
            if ["id", "addedDate", "podcast_id"].contains(child1.label) {
                continue
            }

            // Ensure both values are Equatable
            if let value1 = child1.value as? (any Equatable),
               let value2 = child2.value as? (any Equatable) {
                if !areEqual(value1, value2) {
                    print("❌ \(child1.label ?? ""): \(value1) is not equal to \(value2)")
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }

    // Helper function to compare `any Equatable` values
    private func areEqual(_ lhs: any Equatable, _ rhs: any Equatable) -> Bool {
        return lhs as? AnyHashable == rhs as? AnyHashable
    }
}
