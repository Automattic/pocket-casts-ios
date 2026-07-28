import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Tests for UpNextDataManager using the public API.
/// These tests run with both SQL and GRDB implementations.
final class UpNextDataManagerTests: DataManagerTestCase {

    // MARK: - allUpNextPlaylistEpisodes Tests

    func testAllUpNextPlaylistEpisodesReturnsEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, title: "Episode 1", dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, title: "Episode 2", dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            let playlistEpisodes = dataManager.allUpNextPlaylistEpisodes()

            XCTAssertEqual(playlistEpisodes.count, 2, "\(impl): Should return 2 playlist episodes")
        }
    }

    func testAllUpNextPlaylistEpisodesReturnsEmptyWhenNone() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlistEpisodes = dataManager.allUpNextPlaylistEpisodes()

            XCTAssertTrue(playlistEpisodes.isEmpty, "\(impl): Should return empty when no episodes in Up Next")
        }
    }

    // MARK: - upNextPlayListContains Tests

    func testUpNextPlayListContainsReturnsTrueWhenContains() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "test-episode-uuid", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode.uuid, title: episode.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            let contains = dataManager.upNextPlayListContains(episodeUuid: "test-episode-uuid")

            XCTAssertTrue(contains, "\(impl): Should contain episode")
        }
    }

    func testUpNextPlayListContainsReturnsFalseWhenNotContains() throws {
        try runWithBothImplementations { dataManager, impl in
            let contains = dataManager.upNextPlayListContains(episodeUuid: "non-existent-uuid")

            XCTAssertFalse(contains, "\(impl): Should not contain non-existent episode")
        }
    }

    // MARK: - allUpNextEpisodes Tests

    func testAllUpNextEpisodesReturnsBaseEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, title: "Episode 1", dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, title: "Episode 2", dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            let upNextEpisodes = dataManager.allUpNextEpisodes()

            XCTAssertEqual(upNextEpisodes.count, 2, "\(impl): Should return 2 episodes")
        }
    }

    // MARK: - deleteAllUpNextEpisodes Tests

    func testDeleteAllUpNextEpisodesRemovesAll() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode3 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode3.uuid, title: episode3.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 3, "\(impl): Should have 3 episodes initially")

            dataManager.deleteAllUpNextEpisodes()

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 0, "\(impl): Should have 0 episodes after deletion")
        }
    }

    func testDeleteAllUpNextEpisodesOnEmptyDoesNotCrash() throws {
        try runWithBothImplementations { dataManager, impl in
            dataManager.deleteAllUpNextEpisodes()

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 0, "\(impl): Should not crash on empty Up Next")
        }
    }

    // MARK: - deleteAllUpNextEpisodesExcept Tests

    func testDeleteAllUpNextEpisodesExceptKeepsOneEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)
            let episodeToKeep = self.createTestEpisode(uuid: "episode-to-keep", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episodeToKeep.uuid, title: episodeToKeep.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesExcept(episodeUuid: "episode-to-keep")

            let remaining = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(remaining.count, 1, "\(impl): Should keep only one episode")
            XCTAssertEqual(remaining.first?.episodeUuid, "episode-to-keep", "\(impl): Should keep correct episode")
        }
    }

    func testDeleteAllUpNextEpisodesExceptWithNonExistentDeletesAll() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesExcept(episodeUuid: "non-existent")

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 0, "\(impl): Should delete all when exception episode doesn't exist")
        }
    }

    // MARK: - deleteAllUpNextEpisodesNotIn Tests

    func testDeleteAllUpNextEpisodesNotInKeepsMatchingEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let keep1 = self.createTestEpisode(uuid: "keep-1", podcast: podcast, dataManager: dataManager)
            let keep2 = self.createTestEpisode(uuid: "keep-2", podcast: podcast, dataManager: dataManager)
            let delete1 = self.createTestEpisode(uuid: "delete-1", podcast: podcast, dataManager: dataManager)
            let delete2 = self.createTestEpisode(uuid: "delete-2", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: keep1.uuid, title: keep1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: keep2.uuid, title: keep2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: delete1.uuid, title: delete1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: delete2.uuid, title: delete2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesNotIn(uuids: ["keep-1", "keep-2"])

            let remaining = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(remaining.count, 2, "\(impl): Should keep 2 episodes")
            let uuids = remaining.map { $0.episodeUuid }
            XCTAssertTrue(uuids.contains("keep-1"), "\(impl): Should contain keep-1")
            XCTAssertTrue(uuids.contains("keep-2"), "\(impl): Should contain keep-2")
        }
    }

    func testDeleteAllUpNextEpisodesNotInWithEmptyArrayDeletesAll() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesNotIn(uuids: [])

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 0, "\(impl): Should delete all when empty array")
        }
    }

    // MARK: - deleteAllUpNextEpisodesIn Tests

    func testDeleteAllUpNextEpisodesInDeletesMatchingEpisodes() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let keep1 = self.createTestEpisode(uuid: "keep-1", podcast: podcast, dataManager: dataManager)
            let keep2 = self.createTestEpisode(uuid: "keep-2", podcast: podcast, dataManager: dataManager)
            let delete1 = self.createTestEpisode(uuid: "delete-1", podcast: podcast, dataManager: dataManager)
            let delete2 = self.createTestEpisode(uuid: "delete-2", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: keep1.uuid, title: keep1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: keep2.uuid, title: keep2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: delete1.uuid, title: delete1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: delete2.uuid, title: delete2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesIn(uuids: ["delete-1", "delete-2"])

            let remaining = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(remaining.count, 2, "\(impl): Should keep 2 episodes")
            let uuids = remaining.map { $0.episodeUuid }
            XCTAssertFalse(uuids.contains("delete-1"), "\(impl): Should not contain delete-1")
            XCTAssertFalse(uuids.contains("delete-2"), "\(impl): Should not contain delete-2")
        }
    }

    func testDeleteAllUpNextEpisodesInWithEmptyArrayDoesNothing() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesIn(uuids: [])

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 2, "\(impl): Should keep all when empty array")
        }
    }

    func testDeleteAllUpNextEpisodesInWithNonExistentDoesNothing() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            dataManager.deleteAllUpNextEpisodesIn(uuids: ["non-existent-1", "non-existent-2"])

            XCTAssertEqual(dataManager.allUpNextPlaylistEpisodes().count, 2, "\(impl): Should keep all when UUIDs don't exist")
        }
    }

    // MARK: - saveUpNextAddToTop Tests

    func testSaveUpNextAddToTopAddsToTop() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextTop(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            let episodes = dataManager.allUpNextPlaylistEpisodes()
            // Episode 2 should be at a lower position (closer to top)
            XCTAssertEqual(episodes.count, 2, "\(impl): Should have 2 episodes")
        }
    }

    // MARK: - saveUpNextAddToBottom Tests

    func testSaveUpNextAddToBottomAddsToBottom() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode1 = self.createTestEpisode(uuid: "episode-1", podcast: podcast, dataManager: dataManager)
            let episode2 = self.createTestEpisode(uuid: "episode-2", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode1.uuid, title: episode1.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            self.addToUpNextBottom(episodeUuid: episode2.uuid, title: episode2.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)

            let episodes = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(episodes.count, 2, "\(impl): Should have 2 episodes")
        }
    }

    // MARK: - saveUpNextRemove Tests

    func testSaveUpNextRemoveRemovesEpisode() throws {
        try runWithBothImplementations { dataManager, impl in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "episode-to-remove", podcast: podcast, dataManager: dataManager)

            self.addToUpNextBottom(episodeUuid: episode.uuid, title: episode.title ?? "", podcastUuid: podcast.uuid, dataManager: dataManager)
            XCTAssertTrue(dataManager.upNextPlayListContains(episodeUuid: episode.uuid), "\(impl): Should contain episode initially")

            // Find the playlist episode and delete it
            if let playlistEpisode = dataManager.findPlaylistEpisode(uuid: episode.uuid) {
                dataManager.delete(playlistEpisode: playlistEpisode)
            }

            XCTAssertFalse(dataManager.upNextPlayListContains(episodeUuid: episode.uuid), "\(impl): Should not contain episode after removal")
        }
    }
}
