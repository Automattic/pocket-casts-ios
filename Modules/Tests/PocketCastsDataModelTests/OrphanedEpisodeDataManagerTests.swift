import XCTest
@testable import PocketCastsDataModel

/// Regression coverage for Zendesk 11385087: a duplicate SJEpisode row shares a uuid with the "live"
/// episode, but its podcast_id points at a podcast that was never persisted (podcastUuid still resolves fine).
/// Fixture values below are a trimmed subset of the customer's DB export: podcast "When In Romance"
/// (uuid 9e4aed70-e1df-0135-c259-7d73a919276a) and episode uuid 830f91c2-f7f6-4127-8373-8114ed332ab1,
/// which has exactly this live/orphan pair.
final class OrphanedEpisodeDataManagerTests: DataManagerTestCase {
    private let episodeUuid = "830f91c2-f7f6-4127-8373-8114ed332ab1"
    private let podcastUuid = "9e4aed70-e1df-0135-c259-7d73a919276a"
    private let phantomPodcastId: Int64 = 3_655_752_526_629_178_403

    private struct Fixture {
        let podcast: Podcast
        let live: Episode
        let orphan: Episode
    }

    private func makeFixture(dataManager: DataManager) -> Fixture {
        let podcast = createTestPodcast(uuid: podcastUuid, title: "When In Romance", dataManager: dataManager)

        let live = createTestEpisode(
            uuid: episodeUuid,
            podcast: podcast,
            title: "When in Romance Ep. #0: Welcome to Romancelandia",
            publishedDate: Date(timeIntervalSince1970: 1_516_378_780),
            episodeStatus: DownloadStatus.notDownloaded.rawValue,
            playingStatus: PlayingStatus.notPlayed.rawValue,
            dataManager: dataManager
        )

        let orphan = Episode()
        orphan.uuid = episodeUuid
        orphan.podcastUuid = podcastUuid
        orphan.podcast_id = phantomPodcastId
        orphan.title = live.title
        orphan.addedDate = Date(timeIntervalSince1970: 1_659_215_875)
        orphan.publishedDate = live.publishedDate
        orphan.episodeStatus = DownloadStatus.downloaded.rawValue
        orphan.playingStatus = PlayingStatus.inProgress.rawValue
        orphan.archived = true
        dataManager.save(episode: orphan)

        return Fixture(podcast: podcast, live: live, orphan: orphan)
    }

    func testOrphanedEpisodeIsNotCaughtByGhostEpisodeCleanup() throws {
        try runWithBothImplementations { dataManager, impl in
            let fixture = self.makeFixture(dataManager: dataManager)

            let ghosts = dataManager.findGhostEpisodes()

            XCTAssertFalse(ghosts.contains(where: { $0.id == fixture.orphan.id }), "\(impl): ghost-episode cleanup joins on podcastUuid, which is still valid here, so it should miss this orphan")
        }
    }

    func testFindOrphanedEpisodesReturnsOnlyThePhantomRow() throws {
        try runWithBothImplementations { dataManager, impl in
            let fixture = self.makeFixture(dataManager: dataManager)

            let orphans = dataManager.findOrphanedEpisodes()

            XCTAssertEqual(orphans.map(\.id), [fixture.orphan.id], "\(impl): should find only the row whose podcast_id has no matching SJPodcast row")
        }
    }

    func testDeleteOrphanedEpisodesRemovesOnlyTheOrphanRow() throws {
        try runWithBothImplementations { dataManager, impl in
            let fixture = self.makeFixture(dataManager: dataManager)

            let orphans = dataManager.findOrphanedEpisodes()
            dataManager.deleteOrphanedEpisodes(ids: orphans.map(\.id))

            let remaining = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: [self.episodeUuid])
            XCTAssertEqual(remaining.map(\.id), [fixture.live.id], "\(impl): only the live row should remain")
            XCTAssertNotNil(dataManager.findPodcast(uuid: self.podcastUuid, includeUnsubscribed: true), "\(impl): the real podcast should be untouched")
        }
    }

    func testReconcileOrphanedEpisodeRepointsSurvivorAndDeletesOthersInOneWrite() throws {
        try runWithBothImplementations { dataManager, impl in
            let fixture = self.makeFixture(dataManager: dataManager)

            dataManager.reconcileOrphanedEpisode(survivorId: fixture.orphan.id, realPodcastId: fixture.podcast.id, idsToDelete: [fixture.live.id])

            let remaining = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: [self.episodeUuid])
            XCTAssertEqual(remaining.map(\.id), [fixture.orphan.id], "\(impl): the survivor should remain, the stale live row should be gone")
            XCTAssertEqual(remaining.first?.podcast_id, fixture.podcast.id, "\(impl): the survivor should be repointed at the real podcast")
        }
    }
}
