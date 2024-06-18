import XCTest
import SQLite3
import FMDB
@testable import PocketCastsDataModel

final class PodcastDataManagerTests: XCTestCase {
    private func setupDatabase() throws -> DataManager {
        let dbQueue = try XCTUnwrap(FMDatabaseQueue.newTestDatabase())
        return DataManager(dbQueue: dbQueue)
    }

    private func setupDataManager() throws -> DataManager {
        let dataManager = try setupDatabase()
        let podcastCount = 1000
        let episodeCount = 50

        (0...podcastCount).forEach { idx in
            let podcast = Podcast()
            podcast.uuid = "\(idx)"
            podcast.addedDate = Date()

            dataManager.save(podcast: podcast)

            (0...episodeCount).forEach { _ in
                let episode = Episode()
                episode.uuid = UUID().uuidString
                episode.addedDate = Date()
                episode.podcastUuid = podcast.uuid

                dataManager.save(episode: episode)
            }
        }

        return dataManager
    }

    func testFindPodcastPerformance() throws {
        let dataManager = try setupDataManager()

        self.measure {
            (0...10000).forEach { _ in
                let random = Int.random(in: 0...1000)
                _ = dataManager.findPodcast(uuid: "\(random)")
            }
        }
    }
}
