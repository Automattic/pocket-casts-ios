@testable import PocketCastsDataModel
import GRDB
import XCTest

final class PlaylistDataManagerTests: XCTestCase {

    func testAllSmartPlaylistsReturnsResultsWithoutRawPlaylistTypeFilter() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteValidator.SQLiteError.failedNewTestDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dataManager = DataManager(dbQueue: queue)

        let activeSmart = EpisodeFilter()
        activeSmart.uuid = "smart-active"
        activeSmart.playlistName = "Smart Active"
        activeSmart.manual = false
        activeSmart.sortPosition = 1
        dataManager.save(playlist: activeSmart)

        let deletedSmart = EpisodeFilter()
        deletedSmart.uuid = "smart-deleted"
        deletedSmart.playlistName = "Smart Deleted"
        deletedSmart.manual = false
        deletedSmart.wasDeleted = true
        deletedSmart.sortPosition = 2
        dataManager.save(playlist: deletedSmart)

        let manualPlaylist = EpisodeFilter()
        manualPlaylist.uuid = "manual-playlist"
        manualPlaylist.playlistName = "Manual Playlist"
        manualPlaylist.manual = true
        manualPlaylist.sortPosition = 3
        dataManager.save(playlist: manualPlaylist)

        let smartPlaylists = dataManager.allSmartPlaylists(includeDeleted: false)
        XCTAssertEqual(smartPlaylists.map(\.uuid), ["smart-active"])

        let smartPlaylistsWithDeleted = dataManager.allSmartPlaylists(includeDeleted: true)
        XCTAssertEqual(smartPlaylistsWithDeleted.map(\.uuid), ["smart-active", "smart-deleted"])
    }
}
