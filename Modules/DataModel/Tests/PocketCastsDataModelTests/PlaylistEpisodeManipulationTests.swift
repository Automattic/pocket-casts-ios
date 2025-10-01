@testable import PocketCastsDataModel
import XCTest
import GRDB

final class PlaylistEpisodeManipulationTests: XCTestCase {

    func testMoveAndDeleteEpisodesInManualPlaylist() throws {
        // Fresh DB and DataManager
        guard let dbPool = try DatabasePool.newTestDatabase() else { throw SQLiteValidator.SQLiteError.failedNewTestDatabase }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dm = try DataManager(dbQueue: queue)

        // Create a manual playlist
        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = "pl-1"
        playlist.playlistName = "Test"
        dm.save(playlist: playlist)

        // Add three episodes
        let e1 = Episode(); e1.uuid = "e1"; e1.podcastUuid = "p1"; e1.title = "E1"
        let e2 = Episode(); e2.uuid = "e2"; e2.podcastUuid = "p1"; e2.title = "E2"
        let e3 = Episode(); e3.uuid = "e3"; e3.podcastUuid = "p1"; e3.title = "E3"

        dm.add(episodes: [e1, e2, e3], to: playlist)

        // Move e3 to the top
        dm.moveEpisode("e3", in: playlist, to: 0)

        // Verify order: e3, e1, e2
        try assertPlaylistOrder(dbQueue: queue, playlistUuid: playlist.uuid, expected: ["e3", "e1", "e2"])

        // Delete e1 and reindex
        dm.deleteEpisodes(["e1"], from: playlist)
        try assertPlaylistOrder(dbQueue: queue, playlistUuid: playlist.uuid, expected: ["e3", "e2"])

        // Delete the whole playlist and ensure relationships are cleared
        dm.delete(playlist: playlist)
        let count = countPlaylistEntries(dbQueue: queue, playlistUuid: playlist.uuid)
        XCTAssertEqual(count, 0)
    }

    func testMoveEpisodeMarksPlaylistDirty() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else { throw SQLiteValidator.SQLiteError.failedNewTestDatabase }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dm = try DataManager(dbQueue: queue)

        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = "pl-move"
        playlist.playlistName = "Manual"
        playlist.syncStatus = SyncStatus.synced.rawValue
        dm.save(playlist: playlist)

        let e1 = Episode(); e1.uuid = "m1"; e1.podcastUuid = "p1"; e1.title = "First"
        let e2 = Episode(); e2.uuid = "m2"; e2.podcastUuid = "p1"; e2.title = "Second"
        dm.add(episodes: [e1, e2], to: playlist)

        dm.moveEpisode(e1.uuid, in: playlist, to: 1)

        XCTAssertEqual(playlist.syncStatus, SyncStatus.notSynced.rawValue)
        let reloaded = try XCTUnwrap(dm.findPlaylist(uuid: playlist.uuid))
        XCTAssertEqual(reloaded.syncStatus, SyncStatus.notSynced.rawValue)
    }

    func testDeleteEpisodesMarksPlaylistDirty() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else { throw SQLiteValidator.SQLiteError.failedNewTestDatabase }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dm = try DataManager(dbQueue: queue)

        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = "pl-delete"
        playlist.playlistName = "Manual"
        playlist.syncStatus = SyncStatus.synced.rawValue
        dm.save(playlist: playlist)

        let e1 = Episode(); e1.uuid = "d1"; e1.podcastUuid = "p1"; e1.title = "Delete"
        let e2 = Episode(); e2.uuid = "d2"; e2.podcastUuid = "p1"; e2.title = "Keep"
        dm.add(episodes: [e1, e2], to: playlist)

        dm.deleteEpisodes([e1.uuid], from: playlist)

        XCTAssertEqual(playlist.syncStatus, SyncStatus.notSynced.rawValue)
        let reloaded = try XCTUnwrap(dm.findPlaylist(uuid: playlist.uuid))
        XCTAssertEqual(reloaded.syncStatus, SyncStatus.notSynced.rawValue)
    }

    // Helpers
    private func assertPlaylistOrder(dbQueue: PCDBQueue, playlistUuid: String, expected: [String]) throws {
        let sql = "SELECT episodeUuid FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ? ORDER BY episodePosition ASC"
        var actual = [String]()
        dbQueue.read { db in
            do {
                let rs = try db.executeQuery(sql, values: [playlistUuid])
                defer { rs.close() }
                while rs.next() {
                    if let uuid = rs.string(forColumn: "episodeUuid") { actual.append(uuid) }
                }
            } catch {
                XCTFail("Query failed: \(error)")
            }
        }
        XCTAssertEqual(actual, expected)
    }

    private func countPlaylistEntries(dbQueue: PCDBQueue, playlistUuid: String) -> Int {
        var count = 0
        dbQueue.read { db in
            do {
                let rs = try db.executeQuery("SELECT COUNT(*) c FROM \(DataManager.playlistEpisodeTableName) WHERE playlist_uuid = ?", values: [playlistUuid])
                defer { rs.close() }
                if rs.next() { count = rs.long(forColumn: "c") }
            } catch {
                count = -1
            }
        }
        return count
    }
}
