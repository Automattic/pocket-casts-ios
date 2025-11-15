import XCTest
import GRDB
@testable import PocketCastsDataModel

final class UpNextEpisodeFetchTests: XCTestCase {

    enum TestSetupError: Error {
        case failedToCreateDatabase
    }

    func testEpisodeDataManagerFiltersNonUpNextPlaylists() throws {
        let queue = try makeQueue()
        let episodeManager = EpisodeDataManager()
        let upNextManager = UpNextDataManager()
        upNextManager.setup(dbQueue: queue)

        let upNextEpisode = Episode()
        upNextEpisode.uuid = "ep-upnext"
        upNextEpisode.title = "Up Next Episode"
        upNextEpisode.podcastUuid = "pod-upnext"
        upNextEpisode.addedDate = Date()
        episodeManager.save(episode: upNextEpisode, dbQueue: queue)

        let otherEpisode = Episode()
        otherEpisode.uuid = "ep-other"
        otherEpisode.title = "Other Playlist Episode"
        otherEpisode.podcastUuid = "pod-other"
        otherEpisode.addedDate = Date()
        episodeManager.save(episode: otherEpisode, dbQueue: queue)

        addUpNextEntry(upNextManager: upNextManager, queue: queue, episodeUuid: upNextEpisode.uuid, title: upNextEpisode.title ?? "", podcastUuid: upNextEpisode.podcastUuid, position: 0)
        addPlaylistEntry(queue: queue, episodeUuid: otherEpisode.uuid, playlistId: 999, position: 1, title: otherEpisode.title ?? "", podcastUuid: otherEpisode.podcastUuid)

        let results = episodeManager.allUpNextEpisodes(dbQueue: queue)
        XCTAssertEqual(results.map(\.uuid), [upNextEpisode.uuid])
    }

    func testUserEpisodeDataManagerFiltersNonUpNextPlaylists() throws {
        let queue = try makeQueue()
        let userEpisodeManager = UserEpisodeDataManager()
        let upNextManager = UpNextDataManager()
        upNextManager.setup(dbQueue: queue)

        let upNextUserEpisode = UserEpisode()
        upNextUserEpisode.uuid = "user-ep-upnext"
        upNextUserEpisode.title = "Up Next User Episode"
        upNextUserEpisode.addedDate = Date()
        userEpisodeManager.save(episode: upNextUserEpisode, dbQueue: queue)

        let otherUserEpisode = UserEpisode()
        otherUserEpisode.uuid = "user-ep-other"
        otherUserEpisode.title = "Other Playlist User Episode"
        otherUserEpisode.addedDate = Date()
        userEpisodeManager.save(episode: otherUserEpisode, dbQueue: queue)

        addUpNextEntry(upNextManager: upNextManager, queue: queue, episodeUuid: upNextUserEpisode.uuid, title: upNextUserEpisode.title ?? "", podcastUuid: DataConstants.userEpisodeFakePodcastId, position: 0)
        addPlaylistEntry(queue: queue, episodeUuid: otherUserEpisode.uuid, playlistId: 999, position: 1, title: otherUserEpisode.title ?? "", podcastUuid: DataConstants.userEpisodeFakePodcastId)

        let results = userEpisodeManager.allUpNextEpisodes(dbQueue: queue)
        XCTAssertEqual(results.map(\.uuid), [upNextUserEpisode.uuid])
    }

    func testSavingUpNextEpisodeDoesNotShiftManualPlaylistOrdering() throws {
        let queue = try makeQueue()
        let upNextManager = UpNextDataManager()
        upNextManager.setup(dbQueue: queue)

        let manualPlaylistUuid = "manual-playlist"
        addManualPlaylistEntry(
            queue: queue,
            episodeUuid: "manual-episode-1",
            playlistId: 42,
            playlistUuid: manualPlaylistUuid,
            position: 0,
            title: "Manual Episode 1",
            podcastUuid: "manual-podcast"
        )
        addManualPlaylistEntry(
            queue: queue,
            episodeUuid: "manual-episode-2",
            playlistId: 42,
            playlistUuid: manualPlaylistUuid,
            position: 1,
            title: "Manual Episode 2",
            podcastUuid: "manual-podcast"
        )

        let playlistEpisode = PlaylistEpisode()
        playlistEpisode.episodeUuid = "upnext-1"
        playlistEpisode.title = "Up Next Episode"
        playlistEpisode.podcastUuid = "upnext-podcast"
        playlistEpisode.episodePosition = 0
        upNextManager.save(playlistEpisode: playlistEpisode, dbQueue: queue)

        XCTAssertEqual(fetchManualPlaylistOrder(queue: queue, playlistUuid: manualPlaylistUuid), ["manual-episode-1", "manual-episode-2"])
    }

    func testBulkSavingUpNextEpisodesDoesNotShiftManualPlaylistOrdering() throws {
        let queue = try makeQueue()
        let upNextManager = UpNextDataManager()
        upNextManager.setup(dbQueue: queue)

        let manualPlaylistUuid = "manual-playlist"
        addManualPlaylistEntry(
            queue: queue,
            episodeUuid: "manual-episode-1",
            playlistId: 42,
            playlistUuid: manualPlaylistUuid,
            position: 0,
            title: "Manual Episode 1",
            podcastUuid: "manual-podcast"
        )
        addManualPlaylistEntry(
            queue: queue,
            episodeUuid: "manual-episode-2",
            playlistId: 42,
            playlistUuid: manualPlaylistUuid,
            position: 1,
            title: "Manual Episode 2",
            podcastUuid: "manual-podcast"
        )

        let bulkEpisodes = (0..<3).map { index -> PlaylistEpisode in
            let episode = PlaylistEpisode()
            episode.episodeUuid = "upnext-bulk-\(index)"
            episode.title = "Up Next Bulk \(index)"
            episode.podcastUuid = "upnext-podcast"
            episode.episodePosition = Int32(index)
            return episode
        }
        upNextManager.save(playlistEpisodes: bulkEpisodes, dbQueue: queue)

        XCTAssertEqual(fetchManualPlaylistOrder(queue: queue, playlistUuid: manualPlaylistUuid), ["manual-episode-1", "manual-episode-2"])
    }

    func testDeletingUpNextEpisodesWithEmptyListDoesNotAffectManualPlaylist() throws {
        let queue = try makeQueue()
        let upNextManager = UpNextDataManager()
        upNextManager.setup(dbQueue: queue)

        let manualPlaylistUuid = "manual-playlist"
        addManualPlaylistEntry(
            queue: queue,
            episodeUuid: "manual-episode-1",
            playlistId: 42,
            playlistUuid: manualPlaylistUuid,
            position: 0,
            title: "Manual Episode 1",
            podcastUuid: "manual-podcast"
        )

        let upNextEpisode = PlaylistEpisode()
        upNextEpisode.episodeUuid = "upnext-episode"
        upNextEpisode.title = "Up Next Episode"
        upNextEpisode.podcastUuid = "upnext-podcast"
        upNextEpisode.episodePosition = 0
        upNextManager.save(playlistEpisode: upNextEpisode, dbQueue: queue)

        upNextManager.deleteAllUpNextEpisodesNotIn(uuids: [], dbQueue: queue)

        XCTAssertEqual(fetchManualPlaylistOrder(queue: queue, playlistUuid: manualPlaylistUuid), ["manual-episode-1"])
        XCTAssertTrue(upNextManager.allUpNextPlaylistEpisodes(dbQueue: queue).isEmpty)
    }

    // MARK: - Helpers

    private func makeQueue() throws -> PCDBQueue {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw TestSetupError.failedToCreateDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        return queue
    }

    private func addUpNextEntry(upNextManager: UpNextDataManager, queue: PCDBQueue, episodeUuid: String, title: String, podcastUuid: String, position: Int32) {
        let playlistEpisode = PlaylistEpisode()
        playlistEpisode.episodeUuid = episodeUuid
        playlistEpisode.title = title
        playlistEpisode.podcastUuid = podcastUuid
        playlistEpisode.episodePosition = position
        upNextManager.save(playlistEpisode: playlistEpisode, dbQueue: queue)
    }

    private func addPlaylistEntry(queue: PCDBQueue, episodeUuid: String, playlistId: Int, position: Int, title: String, podcastUuid: String) {
        queue.write { db in
            do {
                try db.executeUpdate(
                    """
                    INSERT INTO \(DataManager.playlistEpisodeTableName)
                    (episodePosition, episodeUuid, playlist_id, upcoming, wasDeleted, title, podcastUuid)
                    VALUES (?, ?, ?, 0, 0, ?, ?)
                    """,
                    values: [
                        position,
                        episodeUuid,
                        playlistId,
                        title,
                        podcastUuid
                    ]
                )
            } catch {
                XCTFail("Failed to insert playlist entry: \(error)")
            }
        }
    }

    private func addManualPlaylistEntry(
        queue: PCDBQueue,
        episodeUuid: String,
        playlistId: Int,
        playlistUuid: String,
        position: Int,
        title: String,
        podcastUuid: String
    ) {
        queue.write { db in
            do {
                try db.executeUpdate(
                    """
                    INSERT INTO \(DataManager.playlistEpisodeTableName)
                    (episodePosition, episodeUuid, playlist_id, upcoming, wasDeleted, title, podcastUuid, playlist_uuid)
                    VALUES (?, ?, ?, 0, 0, ?, ?, ?)
                    """,
                    values: [
                        position,
                        episodeUuid,
                        playlistId,
                        title,
                        podcastUuid,
                        playlistUuid
                    ]
                )
            } catch {
                XCTFail("Failed to insert manual playlist entry: \(error)")
            }
        }
    }

    private func fetchManualPlaylistOrder(queue: PCDBQueue, playlistUuid: String) -> [String] {
        var order = [String]()
        queue.read { db in
            do {
                let rs = try db.executeQuery(
                    "SELECT episodeUuid FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? ORDER BY episodePosition ASC",
                    values: [playlistUuid]
                )
                defer { rs.close() }
                while rs.next() {
                    order.append(DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "episodeUuid"))
                }
            } catch {
                XCTFail("Failed to fetch manual playlist order: \(error)")
            }
        }
        return order
    }
}
