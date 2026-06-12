import XCTest
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for `DataManager.deleteAllData`, the full local-data wipe used by tvOS logout.
final class DataManagerDeleteAllDataTests: DataManagerTestCase {

    func testDeleteAllDataClearsEveryTable() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(uuid: "podcast-1", dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            _ = self.createTestUserEpisode(uuid: "user-episode-1", dataManager: dataManager)
            _ = self.createTestPlaylist(dataManager: dataManager)
            _ = self.createTestFolder(dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode.uuid, podcastUuid: podcast.uuid, dataManager: dataManager)

            XCTAssertFalse(dataManager.allPodcasts(includeUnsubscribed: true).isEmpty, "\(impl): expected podcasts before wipe")
            XCTAssertNotNil(dataManager.findEpisode(uuid: "episode-1"), "\(impl): expected episode before wipe")
            XCTAssertFalse(dataManager.allUpNextEpisodes().isEmpty, "\(impl): expected up next before wipe")

            dataManager.deleteAllData()

            XCTAssertTrue(dataManager.allPodcasts(includeUnsubscribed: true).isEmpty, "\(impl): podcasts should be cleared")
            XCTAssertNil(dataManager.findEpisode(uuid: "episode-1"), "\(impl): episodes should be cleared")
            XCTAssertNil(dataManager.findUserEpisode(uuid: "user-episode-1"), "\(impl): user episodes should be cleared")
            XCTAssertTrue(dataManager.allPlaylists(includeDeleted: true).isEmpty, "\(impl): playlists should be cleared")
            XCTAssertTrue(dataManager.allFolders(includeDeleted: true).isEmpty, "\(impl): folders should be cleared")
            XCTAssertTrue(dataManager.allUpNextEpisodes().isEmpty, "\(impl): up next should be cleared")
        }
    }

    func testDeleteAllDataLeavesDatabaseUsable() throws {
        try runWithBothImplementations { dataManager, impl in
            _ = self.createTestPodcast(uuid: "before-wipe", dataManager: dataManager)

            dataManager.deleteAllData()

            _ = self.createTestPodcast(uuid: "after-wipe", title: "After Wipe", dataManager: dataManager)

            let podcasts = dataManager.allPodcasts(includeUnsubscribed: true)
            XCTAssertEqual(podcasts.count, 1, "\(impl): database should be usable after the wipe")
            XCTAssertEqual(podcasts.first?.uuid, "after-wipe", "\(impl): only the post-wipe podcast should remain")
        }
    }
}
