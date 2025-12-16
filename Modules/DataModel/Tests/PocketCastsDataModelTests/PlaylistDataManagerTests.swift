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

    func testFirstSortPosition() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteValidator.SQLiteError.failedNewTestDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dataManager = DataManager(dbQueue: queue)

        let playlist1 = EpisodeFilter()
        playlist1.uuid = UUID().uuidString
        playlist1.playlistName = "Playlist 1"
        playlist1.sortPosition = 7
        dataManager.save(playlist: playlist1)

        let playlist2 = EpisodeFilter()
        playlist2.uuid = UUID().uuidString
        playlist2.playlistName = "Playlist 2"
        playlist2.sortPosition = 1
        dataManager.save(playlist: playlist2)

        let playlist3 = EpisodeFilter()
        playlist3.uuid = UUID().uuidString
        playlist3.playlistName = "Playlist 3"
        playlist3.sortPosition = 349
        dataManager.save(playlist: playlist3)

        let firstSortPosition = dataManager.firstSortPositionForPlaylist()
        XCTAssertEqual(firstSortPosition, 1)
    }

    func testBumpSortPosition() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteValidator.SQLiteError.failedNewTestDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dataManager = DataManager(dbQueue: queue)

        let playlist1 = EpisodeFilter()
        playlist1.uuid = UUID().uuidString
        playlist1.playlistName = "Playlist 1"
        playlist1.sortPosition = 1
        dataManager.save(playlist: playlist1)

        let playlist2 = EpisodeFilter()
        playlist2.uuid = UUID().uuidString
        playlist2.playlistName = "Playlist 2"
        playlist2.sortPosition = 2
        dataManager.save(playlist: playlist2)

        let playlist3 = EpisodeFilter()
        playlist3.uuid = UUID().uuidString
        playlist3.playlistName = "Playlist 3"
        playlist3.sortPosition = 3
        dataManager.save(playlist: playlist3)

        dataManager.bumpSortPositionForAllPlaylists()

        let allPlaylists = dataManager.allPlaylists(includeDeleted: true)
        XCTAssertEqual(allPlaylists.map(\.sortPosition), [2, 3, 4])

        let firstSortPosition = max(0, dataManager.firstSortPositionForPlaylist())

        XCTAssertEqual(firstSortPosition, 2)

        dataManager.bumpSortPositionForAllPlaylists(adding: 2)

        let playlist4 = EpisodeFilter()
        playlist4.uuid = UUID().uuidString
        playlist4.playlistName = "Playlist 4"
        playlist4.sortPosition = Int32(firstSortPosition)
        dataManager.save(playlist: playlist4)

        let playlist5 = EpisodeFilter()
        playlist5.uuid = UUID().uuidString
        playlist5.playlistName = "Playlist 5"
        playlist5.sortPosition = Int32(firstSortPosition + 1)
        dataManager.save(playlist: playlist5)

        let newAllPlaylists = dataManager.allPlaylists(includeDeleted: true)
        XCTAssertEqual(newAllPlaylists.map(\.sortPosition), [2, 3, 4, 5, 6])
    }

    func testPlaylistUpdateDate() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteValidator.SQLiteError.failedNewTestDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dataManager = DataManager(dbQueue: queue)

        let playlist = EpisodeFilter()
        playlist.uuid = UUID().uuidString
        playlist.playlistName = "Playlist 1"

        dataManager.save(playlist: playlist)

        let newPlaylist1 = try XCTUnwrap(dataManager.findPlaylist(uuid: playlist.uuid))

        XCTAssertNotNil(newPlaylist1.playlistUpdateDate)

        let date = Date.now

        dataManager.updatePlaylistUpdateDate(for: newPlaylist1, to: date)

        let newPlaylist2 = try XCTUnwrap(dataManager.findPlaylist(uuid: newPlaylist1.uuid))
        let newPlaylist2Date = try XCTUnwrap(newPlaylist2.playlistUpdateDate)

        XCTAssertEqual(
            newPlaylist2Date.timeIntervalSince1970,
            date.timeIntervalSince1970,
            accuracy: 0.001
        )
    }
}
