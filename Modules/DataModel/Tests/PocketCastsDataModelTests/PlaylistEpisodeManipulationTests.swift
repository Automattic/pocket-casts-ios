@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest

/// Ensures playlist episode manipulation keeps manual playlists consistent
/// while exercising both SQL and GRDB implementations.
final class PlaylistEpisodeManipulationTests: DataManagerTestCase {

    func testMoveAndDeleteEpisodesInManualPlaylist() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = makeManualPlaylist(uuid: "pl-1", name: "Test")
            dataManager.save(playlist: playlist)

            let e1 = makeEpisode(uuid: "e1")
            let e2 = makeEpisode(uuid: "e2")
            let e3 = makeEpisode(uuid: "e3")

            XCTAssertTrue(dataManager.add(episodes: [e1, e2, e3], to: playlist), "\(impl): should add episodes")

            dataManager.moveEpisode("e3", in: playlist, to: 0)
            try assertPlaylistOrder(dataManager: dataManager, playlistUuid: playlist.uuid, expected: ["e3", "e1", "e2"], impl: impl)

            dataManager.deleteEpisodes(["e1"], from: playlist)
            try assertPlaylistOrder(dataManager: dataManager, playlistUuid: playlist.uuid, expected: ["e3", "e2"], impl: impl)

            dataManager.delete(playlist: playlist)
            XCTAssertEqual(countPlaylistEntries(dataManager: dataManager, playlistUuid: playlist.uuid), 0, "\(impl): playlist entries should be removed")
        }
    }

    func testMoveEpisodeMarksPlaylistDirty() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = makeManualPlaylist(uuid: "pl-move", name: "Manual")
            playlist.syncStatus = SyncStatus.synced.rawValue
            dataManager.save(playlist: playlist)

            let e1 = makeEpisode(uuid: "m1")
            let e2 = makeEpisode(uuid: "m2")
            XCTAssertTrue(dataManager.add(episodes: [e1, e2], to: playlist), "\(impl): should add episodes")

            dataManager.moveEpisode(e1.uuid, in: playlist, to: 1)

            XCTAssertEqual(playlist.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): playlist should be marked dirty")
            let reloaded = try XCTUnwrap(dataManager.findPlaylist(uuid: playlist.uuid), "\(impl): playlist should reload")
            XCTAssertEqual(reloaded.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): persisted playlist should be dirty")
        }
    }

    func testDeleteEpisodesMarksPlaylistDirty() throws {
        try runWithBothImplementations { dataManager, impl in
            let playlist = makeManualPlaylist(uuid: "pl-delete", name: "Manual")
            playlist.syncStatus = SyncStatus.synced.rawValue
            dataManager.save(playlist: playlist)

            let e1 = makeEpisode(uuid: "d1")
            let e2 = makeEpisode(uuid: "d2")
            XCTAssertTrue(dataManager.add(episodes: [e1, e2], to: playlist), "\(impl): should add episodes")

            dataManager.deleteEpisodes([e1.uuid], from: playlist)

            XCTAssertEqual(playlist.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): playlist should be marked dirty")
            let reloaded = try XCTUnwrap(dataManager.findPlaylist(uuid: playlist.uuid), "\(impl): playlist should reload")
            XCTAssertEqual(reloaded.syncStatus, SyncStatus.notSynced.rawValue, "\(impl): persisted playlist should be dirty")
        }
    }

    // MARK: - Helpers

    private func makeEpisode(uuid: String) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = "p1"
        episode.title = uuid
        return episode
    }

    private func makeManualPlaylist(uuid: String, name: String) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = uuid
        playlist.playlistName = name
        return playlist
    }

    private func assertPlaylistOrder(dataManager: DataManager, playlistUuid: String, expected: [String], impl: String) throws {
        let sql = """
        SELECT episodeUuid FROM \(DataManager.playlistEpisodeTableName)
        WHERE playlist_uuid = ?
        ORDER BY episodePosition ASC
        """
        var actual = [String]()
        dataManager.testDbQueue.read { db in
            do {
                let rs = try db.executeQuery(sql, values: [playlistUuid])
                defer { rs.close() }
                while rs.next() {
                    actual.append(DBUtils.nonNilStringFromColumn(resultSet: rs, columnName: "episodeUuid"))
                }
            } catch {
                XCTFail("\(impl): query failed \(error)")
            }
        }
        XCTAssertEqual(actual, expected, "\(impl): playlist order should match")
    }

    private func countPlaylistEntries(dataManager: DataManager, playlistUuid: String) -> Int {
        var count = 0
        dataManager.testDbQueue.read { db in
            do {
                let rs = try db.executeQuery(
                    "SELECT COUNT(*) c FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ?",
                    values: [playlistUuid]
                )
                defer { rs.close() }
                if rs.next() { count = rs.long(forColumn: "c") }
            } catch {
                count = -1
            }
        }
        return count
    }
}
