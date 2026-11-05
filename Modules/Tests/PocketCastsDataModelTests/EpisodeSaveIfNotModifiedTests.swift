import XCTest
import GRDB
@testable import PocketCastsDataModel
import PocketCastsUtils

/// Checks the updates the sync makes for each changed episode: they look the episode up by its UUID and skip episodes with unsynced local changes.
final class EpisodeSaveIfNotModifiedTests: DataManagerTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FeatureFlagOverrideStore().override(FeatureFlag.episodeQueryIndexHints, withValue: true)
    }

    override func tearDown() {
        FeatureFlagOverrideStore().resetOverrides()
        super.tearDown()
    }

    func testQueriesUseTheUuidIndex() throws {
        let fields = [
            (name: "playingStatus", modifiedName: "playingStatusModified", modifiedIndex: "episode_playing_status_modified"),
            (name: "keepEpisode", modifiedName: "keepEpisodeModified", modifiedIndex: "episode_keep_episode_modified"),
            (name: "archived", modifiedName: "archivedModified", modifiedIndex: "episode_archived_modified")
        ]

        try runWithDataManager { dataManager in
            for field in fields {
                let query = EpisodeDataManager.saveFieldIfNotModifiedQuery(fieldName: field.name, modifiedFieldName: field.modifiedName)
                let plan = try dataManager.dbQueue.dbPool.read { db in
                    try Row.fetchAll(db, sql: "EXPLAIN QUERY PLAN \(query)", arguments: [1, "uuid"])
                        .map { $0["detail"] as String }
                        .joined(separator: "\n")
                }

                XCTAssertTrue(plan.contains("episode_uuid"), "\(field.name): \(plan)")
                XCTAssertFalse(plan.contains(field.modifiedIndex), "\(field.name): \(plan)")
            }
        }
    }

    func testPlayingStatusUpdatesOnlyEpisodesWithoutLocalChanges() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let unmodified = self.addEpisode(podcast: podcast, dataManager: dataManager)
            let modified = self.addEpisode(podcast: podcast, dataManager: dataManager) {
                $0.playingStatusModified = 1_700_000_000_000
            }

            XCTAssertTrue(dataManager.saveIfNotModified(playingStatus: .completed, episodeUuid: unmodified.uuid))
            XCTAssertFalse(dataManager.saveIfNotModified(playingStatus: .completed, episodeUuid: modified.uuid))

            XCTAssertEqual(dataManager.findEpisode(uuid: unmodified.uuid)?.playingStatus, PlayingStatus.completed.rawValue)
            XCTAssertEqual(dataManager.findEpisode(uuid: modified.uuid)?.playingStatus, PlayingStatus.notPlayed.rawValue)
        }
    }

    func testStarredUpdatesOnlyEpisodesWithoutLocalChanges() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let unmodified = self.addEpisode(podcast: podcast, dataManager: dataManager)
            let modified = self.addEpisode(podcast: podcast, dataManager: dataManager) {
                $0.keepEpisodeModified = 1_700_000_000_000
            }

            XCTAssertTrue(dataManager.saveIfNotModified(starred: true, episodeUuid: unmodified.uuid))
            XCTAssertFalse(dataManager.saveIfNotModified(starred: true, episodeUuid: modified.uuid))

            XCTAssertEqual(dataManager.findEpisode(uuid: unmodified.uuid)?.keepEpisode, true)
            XCTAssertEqual(dataManager.findEpisode(uuid: modified.uuid)?.keepEpisode, false)
        }
    }

    func testArchivedUpdatesOnlyEpisodesWithoutLocalChanges() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let unmodified = self.addEpisode(podcast: podcast, dataManager: dataManager)
            let modified = self.addEpisode(podcast: podcast, dataManager: dataManager) {
                $0.archivedModified = 1_700_000_000_000
            }

            XCTAssertTrue(dataManager.saveIfNotModified(archived: true, episodeUuid: unmodified.uuid))
            XCTAssertFalse(dataManager.saveIfNotModified(archived: true, episodeUuid: modified.uuid))

            XCTAssertEqual(dataManager.findEpisode(uuid: unmodified.uuid)?.archived, true)
            XCTAssertEqual(dataManager.findEpisode(uuid: modified.uuid)?.archived, false)
        }
    }

    private func addEpisode(podcast: Podcast, dataManager: DataManager, configure: (Episode) -> Void = { _ in }) -> Episode {
        let episode = Episode()
        episode.uuid = UUID().uuidString
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.addedDate = Date()
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        configure(episode)
        dataManager.save(episode: episode)
        return episode
    }
}
