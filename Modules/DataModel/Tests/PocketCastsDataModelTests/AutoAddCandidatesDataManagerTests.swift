import XCTest
import FMDB
@testable import PocketCastsUtils
import SQLite3
@testable import PocketCastsDataModel

final class AutoAddCandidatesDataManagerTests: XCTestCase {

    private let featureFlagMock = FeatureFlagMock()

    enum TestError: Error {
        case dbFolderPathFailure
    }

    private func setupDatabase() throws -> DataManager {
        let dbQueue = try XCTUnwrap(FMDatabaseQueue.newTestDatabase())
        return DataManager(dbQueue: dbQueue)
    }

    /// Tests new query and autoAddToUpNext property for UpNext candidates
    func testSyncableUpNextSetting() throws {
        featureFlagMock.set(.newSettingsStorage, value: true)

        let dataManager = try setupDatabase()
        let newUpNextSetting = AutoAddToUpNextSetting.addFirst

        let podcast = Podcast()
        podcast.uuid = "1234"
        podcast.addedDate = Date()
        podcast.setAutoAddToUpNext(setting: newUpNextSetting)

        let episode = Episode()
        episode.uuid = "1234"
        episode.addedDate = Date()
        episode.podcastUuid = podcast.uuid

        dataManager.save(podcast: podcast)
        dataManager.save(episode: episode)
        dataManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)

        let candidates = dataManager.autoAddCandidates.candidates()

        let matchingCandidate = candidates.first(where: { $0.episodeUuid == episode.uuid })
        XCTAssertNotNil(matchingCandidate, "Episode should appear in Up Next candidates")
        XCTAssertEqual(matchingCandidate?.autoAddToUpNextSetting, newUpNextSetting)

        featureFlagMock.reset()
    }

    /// Tests old query and autoAddToUpNext property for UpNext candidates
    func testOldUpNextSetting() throws {
        featureFlagMock.set(.newSettingsStorage, value: false)

        let dataManager = try setupDatabase()
        let newUpNextSetting = AutoAddToUpNextSetting.addFirst

        let podcast = Podcast()
        podcast.uuid = "1234"
        podcast.addedDate = Date()
        podcast.setAutoAddToUpNext(setting: newUpNextSetting)

        let episode = Episode()
        episode.uuid = "1234"
        episode.addedDate = Date()
        episode.podcastUuid = podcast.uuid

        dataManager.save(podcast: podcast)
        dataManager.save(episode: episode)
        dataManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)

        let candidates = dataManager.autoAddCandidates.candidates()

        let matchingCandidate = candidates.first(where: { $0.episodeUuid == episode.uuid })
        XCTAssertNotNil(matchingCandidate, "Episode should appear in Up Next candidates")
        XCTAssertEqual(matchingCandidate?.autoAddToUpNextSetting, newUpNextSetting)

        featureFlagMock.reset()
    }

    func testOldQueryPerformance() throws {
        featureFlagMock.set(.newSettingsStorage, value: false)

        let dataManager = try setupDatabase()
        let newUpNextSetting = AutoAddToUpNextSetting.addFirst

        let podcastCount = 500
        let episodeCount = 50
        (0...podcastCount).forEach { _ in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString
            podcast.addedDate = Date()
            podcast.setAutoAddToUpNext(setting: newUpNextSetting)

            dataManager.save(podcast: podcast)
            (0...episodeCount).forEach { _ in
                let episode = Episode()
                episode.uuid = UUID().uuidString
                episode.addedDate = Date()
                episode.podcastUuid = podcast.uuid

                dataManager.save(episode: episode)
                dataManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)
            }
        }

        self.measure {
            _ = dataManager.autoAddCandidates.candidates()
        }

        featureFlagMock.reset()
    }

    func testNewQueryPerformance() throws {
        featureFlagMock.set(.newSettingsStorage, value: true)

        let dataManager = try setupDatabase()
        let newUpNextSetting = AutoAddToUpNextSetting.addFirst

        let podcastCount = 500
        let episodeCount = 50
        (0...podcastCount).forEach { _ in
            let podcast = Podcast()
            podcast.uuid = UUID().uuidString
            podcast.addedDate = Date()
            podcast.setAutoAddToUpNext(setting: newUpNextSetting)

            dataManager.save(podcast: podcast)
            (0...episodeCount).forEach { _ in
                let episode = Episode()
                episode.uuid = UUID().uuidString
                episode.addedDate = Date()
                episode.podcastUuid = podcast.uuid

                dataManager.save(episode: episode)
                dataManager.autoAddCandidates.add(podcastUUID: podcast.uuid, episodeUUID: episode.uuid)
            }
        }

        self.measure {
            _ = dataManager.autoAddCandidates.candidates()
        }

        featureFlagMock.reset()
    }
}
