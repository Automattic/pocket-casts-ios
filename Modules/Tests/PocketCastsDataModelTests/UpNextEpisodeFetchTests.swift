@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest

/// Verifies UpNext episode fetching and ordering.
final class UpNextEpisodeFetchTests: DataManagerTestCase {

    func testEpisodeDataManagerFiltersNonUpNextPlaylists() throws {
        try runWithDataManager { dataManager in
            let upNextEpisode = Episode()
            upNextEpisode.uuid = "ep-upnext"
            upNextEpisode.title = "Up Next Episode"
            upNextEpisode.podcastUuid = "pod-upnext"
            upNextEpisode.addedDate = Date()

            let otherEpisode = Episode()
            otherEpisode.uuid = "ep-other"
            otherEpisode.title = "Other Playlist Episode"
            otherEpisode.podcastUuid = "pod-other"
            otherEpisode.addedDate = Date()

            dataManager.save(episode: upNextEpisode)
            dataManager.save(episode: otherEpisode)

            saveUpNextEpisode(
                dataManager: dataManager,
                episodeUuid: upNextEpisode.uuid,
                title: upNextEpisode.title ?? "",
                podcastUuid: upNextEpisode.podcastUuid,
                position: 0
            )
            addPlaylistEntry(
                queue: dataManager.testDbQueue,
                episodeUuid: otherEpisode.uuid,
                playlistId: 999,
                position: 1,
                title: otherEpisode.title ?? "",
                podcastUuid: otherEpisode.podcastUuid
            )

            let results = dataManager.allUpNextEpisodes()
            XCTAssertEqual(results.map(\.uuid), [upNextEpisode.uuid], "should only return up next episodes")
        }
    }

    func testUserEpisodeDataManagerFiltersNonUpNextPlaylists() throws {
        try runWithDataManager { dataManager in
            let upNextUserEpisode = UserEpisode()
            upNextUserEpisode.uuid = "user-ep-upnext"
            upNextUserEpisode.title = "Up Next User Episode"
            upNextUserEpisode.addedDate = Date()

            let otherUserEpisode = UserEpisode()
            otherUserEpisode.uuid = "user-ep-other"
            otherUserEpisode.title = "Other Playlist User Episode"
            otherUserEpisode.addedDate = Date()

            dataManager.save(episode: upNextUserEpisode)
            dataManager.save(episode: otherUserEpisode)

            saveUpNextEpisode(
                dataManager: dataManager,
                episodeUuid: upNextUserEpisode.uuid,
                title: upNextUserEpisode.title ?? "",
                podcastUuid: DataConstants.userEpisodeFakePodcastId,
                position: 0
            )
            addPlaylistEntry(
                queue: dataManager.testDbQueue,
                episodeUuid: otherUserEpisode.uuid,
                playlistId: 999,
                position: 1,
                title: otherUserEpisode.title ?? "",
                podcastUuid: DataConstants.userEpisodeFakePodcastId
            )

            let results = dataManager.allUpNextEpisodes()
            XCTAssertEqual(results.map(\.uuid), [upNextUserEpisode.uuid], "should only return up next user episodes")
        }
    }

    func testSavingUpNextEpisodeShiftsExistingUpNextEntries() throws {
        try runWithDataManager { dataManager in
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "existing-0", title: "Existing 0", podcastUuid: "pod", position: 0)
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "existing-1", title: "Existing 1", podcastUuid: "pod", position: 1)

            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "incoming-episode", title: "Incoming Episode", podcastUuid: "pod", position: 0)

            let episodes = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(episodes.map(\.episodeUuid), ["incoming-episode", "existing-0", "existing-1"], "incoming should shift existing")
            XCTAssertEqual(episodes.map { Int($0.episodePosition) }, [0, 1, 2], "positions should reindex")
        }
    }

    func testBulkSavingUpNextEpisodesShiftsExistingEntries() throws {
        try runWithDataManager { dataManager in
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "existing-0", title: "Existing 0", podcastUuid: "pod", position: 0)
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "existing-1", title: "Existing 1", podcastUuid: "pod", position: 1)

            let incomingEpisodes = (0..<2).map { index -> PlaylistEpisode in
                let episode = PlaylistEpisode()
                episode.episodeUuid = "incoming-\(index)"
                episode.title = "Incoming \(index)"
                episode.podcastUuid = "pod"
                episode.episodePosition = Int32(index)
                return episode
            }
            dataManager.save(playlistEpisodes: incomingEpisodes)

            let episodes = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(episodes.map(\.episodeUuid), ["incoming-0", "incoming-1", "existing-0", "existing-1"], "bulk insert should shift existing")
            XCTAssertEqual(episodes.map { Int($0.episodePosition) }, [0, 1, 2, 3], "positions should reindex")
        }
    }

    func testDeleteAllUpNextEpisodesNotInKeepsSpecifiedUpNextEpisodes() throws {
        try runWithDataManager { dataManager in
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "to-keep", title: "Keep", podcastUuid: "pod", position: 0)
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "to-remove-1", title: "Remove 1", podcastUuid: "pod", position: 1)
            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "to-remove-2", title: "Remove 2", podcastUuid: "pod", position: 2)

            dataManager.deleteAllUpNextEpisodesNotIn(uuids: ["to-keep"])

            let episodes = dataManager.allUpNextPlaylistEpisodes()
            XCTAssertEqual(episodes.map(\.episodeUuid), ["to-keep"], "only kept episode should remain")
            XCTAssertEqual(episodes.map { Int($0.episodePosition) }, [0], "positions should start at zero")
        }
    }

    func testSavingUpNextEpisodeDoesNotShiftManualPlaylistOrdering() throws {
        try runWithDataManager { dataManager in
            let manualPlaylistUuid = "manual-playlist"
            addManualPlaylistEntry(
                queue: dataManager.testDbQueue,
                episodeUuid: "manual-episode-1",
                playlistId: 42,
                playlistUuid: manualPlaylistUuid,
                position: 0,
                title: "Manual Episode 1",
                podcastUuid: "manual-podcast"
            )
            addManualPlaylistEntry(
                queue: dataManager.testDbQueue,
                episodeUuid: "manual-episode-2",
                playlistId: 42,
                playlistUuid: manualPlaylistUuid,
                position: 1,
                title: "Manual Episode 2",
                podcastUuid: "manual-podcast"
            )

            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "upnext-1", title: "Up Next Episode", podcastUuid: "upnext-podcast", position: 0)

            XCTAssertEqual(
                fetchManualPlaylistOrder(queue: dataManager.testDbQueue, playlistUuid: manualPlaylistUuid),
                ["manual-episode-1", "manual-episode-2"],
                "manual playlist ordering should be unchanged"
            )
        }
    }

    func testBulkSavingUpNextEpisodesDoesNotShiftManualPlaylistOrdering() throws {
        try runWithDataManager { dataManager in
            let manualPlaylistUuid = "manual-playlist"
            addManualPlaylistEntry(
                queue: dataManager.testDbQueue,
                episodeUuid: "manual-episode-1",
                playlistId: 42,
                playlistUuid: manualPlaylistUuid,
                position: 0,
                title: "Manual Episode 1",
                podcastUuid: "manual-podcast"
            )
            addManualPlaylistEntry(
                queue: dataManager.testDbQueue,
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
            dataManager.save(playlistEpisodes: bulkEpisodes)

            XCTAssertEqual(
                fetchManualPlaylistOrder(queue: dataManager.testDbQueue, playlistUuid: manualPlaylistUuid),
                ["manual-episode-1", "manual-episode-2"],
                "manual playlist ordering should remain unchanged"
            )
        }
    }

    func testDeletingUpNextEpisodesWithEmptyListDoesNotAffectManualPlaylist() throws {
        try runWithDataManager { dataManager in
            let manualPlaylistUuid = "manual-playlist"
            addManualPlaylistEntry(
                queue: dataManager.testDbQueue,
                episodeUuid: "manual-episode-1",
                playlistId: 42,
                playlistUuid: manualPlaylistUuid,
                position: 0,
                title: "Manual Episode 1",
                podcastUuid: "manual-podcast"
            )

            saveUpNextEpisode(dataManager: dataManager, episodeUuid: "upnext-episode", title: "Up Next Episode", podcastUuid: "upnext-podcast", position: 0)

            dataManager.deleteAllUpNextEpisodesNotIn(uuids: [])

            XCTAssertEqual(
                fetchManualPlaylistOrder(queue: dataManager.testDbQueue, playlistUuid: manualPlaylistUuid),
                ["manual-episode-1"],
                "manual playlist should be unchanged"
            )
            XCTAssertTrue(dataManager.allUpNextPlaylistEpisodes().isEmpty, "up next should be empty")
        }
    }

    // MARK: - Helpers

    private func saveUpNextEpisode(dataManager: DataManager, episodeUuid: String, title: String, podcastUuid: String, position: Int32) {
        let playlistEpisode = PlaylistEpisode()
        playlistEpisode.episodeUuid = episodeUuid
        playlistEpisode.title = title
        playlistEpisode.podcastUuid = podcastUuid
        playlistEpisode.episodePosition = position
        dataManager.save(playlistEpisode: playlistEpisode)
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
