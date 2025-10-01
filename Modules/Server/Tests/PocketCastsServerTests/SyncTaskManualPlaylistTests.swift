@testable import PocketCastsServer
@testable import PocketCastsDataModel
import XCTest
import GRDB
import SwiftProtobuf

final class SyncTaskManualPlaylistTests: XCTestCase {
    private var dataManager: DataManager!
    private var syncTask: SyncTask!

    override func setUp() {
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try! DatabasePool(path: NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite"))))
        syncTask = SyncTask(dataManager: dataManager)

        // Ensure any static usage reads from this DB
        DataManager.sharedManager = dataManager
    }

    func testChangedFiltersIncludesManualEpisodesAndFlag() {
        // Seed episodes used by the manual playlist
        let e1 = Episode()
        e1.uuid = "m-1"
        e1.podcastUuid = "p-1"
        e1.podcast_id = 1
        e1.title = "Ep 1"
        e1.downloadUrl = "http://example.com/1.mp3"
        e1.addedDate = Date(timeIntervalSince1970: 100)
        dataManager.save(episode: e1)

        let e2 = Episode()
        e2.uuid = "m-2"
        e2.podcastUuid = "p-2"
        e2.podcast_id = 2
        e2.title = "Ep 2"
        e2.downloadUrl = "http://example.com/2.mp3"
        e2.addedDate = Date(timeIntervalSince1970: 200)
        dataManager.save(episode: e2)

        // Add a manual playlist with the seeded episodes
        let filter = EpisodeFilter()
        filter.uuid = "playlist-1"
        filter.playlistName = "Manual"
        filter.manual = true
        filter.sortType = PlaylistSort.dragAndDrop.rawValue
        filter.syncStatus = SyncStatus.notSynced.rawValue
        dataManager.save(playlist: filter)
        let episodes = [e1, e2]
        dataManager.add(episodes: episodes, to: filter)

        let records = syncTask.changedPlaylists()
        let playlistRecords = records?.compactMap { $0.record }.compactMap { record -> Api_SyncUserPlaylist? in
            if case let .playlist(p) = record { return p }
            return nil
        }

        XCTAssertEqual(playlistRecords?.count, 1)
        let playlist = try! XCTUnwrap(playlistRecords?.first)

        // Episodes should be present and ordered
        XCTAssertEqual(playlist.episodes.count, 2)
        episodes.forEach { episode in
            let hasEpisode = playlist.episodes.contains(where: { playlistEpisode in
                playlistEpisode.episode == episode.uuid
            })
            XCTAssertTrue(hasEpisode)
        }
        XCTAssertEqual(playlist.episodeOrder, [e1.uuid, e2.uuid])
        XCTAssertTrue(playlist.manual.value)
    }

    func testEpisodeFromServerPlaylistEpisodeCreatesEpisode() {
        // Prepare a proto playlist episode
        var proto = Api_SyncPlaylistEpisode()
        proto.episode = "uuid-123"
        proto.podcast = "pod-123"
        proto.added = Google_Protobuf_Int64Value(123_000) // milliseconds
        proto.title.value = "Title"
        proto.url.value = "http://example.com/ep.mp3"

        let episode = Episode(proto)

        XCTAssertEqual(episode.uuid, "uuid-123")
        XCTAssertEqual(episode.podcastUuid, "pod-123")
        XCTAssertEqual(episode.title, "Title")
        XCTAssertEqual(episode.downloadUrl, "http://example.com/ep.mp3")
        XCTAssertEqual(episode.addedDate?.timeIntervalSince1970, 123_000)
    }

    func testProcessServerDataAddsMissingEpisodesFromPlaylist() {
        // One existing episode, one missing
        let existing = Episode()
        existing.uuid = "exist-1"
        existing.podcastUuid = "p1"
        existing.podcast_id = 1
        existing.title = "Existing"
        existing.addedDate = Date()
        existing.playingStatus = PlayingStatus.notPlayed.rawValue
        existing.episodeStatus = DownloadStatus.notDownloaded.rawValue
        dataManager.save(episode: existing)

        // Build a playlist record containing both
        var playlist = Api_SyncUserPlaylist()
        playlist.originalUuid = "pl-1"
        playlist.uuid = "pl-1"
        playlist.title.value = "Server PL"
        playlist.manual = false // ensure importFilter path runs
        playlist.episodeOrder = ["exist-1", "miss-2"]

        var missProto = Api_SyncPlaylistEpisode()
        missProto.episode = "miss-2"
        missProto.podcast = "p2"
        missProto.title.value = "Missing from DB"
        missProto.url.value = "http://example.com/missing.mp3"
        missProto.added = Google_Protobuf_Int64Value(456_000)
        playlist.episodes = [
            {
                var p = Api_SyncPlaylistEpisode()
                p.episode = existing.uuid
                p.podcast = existing.podcastUuid
                return p
            }(),
            missProto
        ]

        var record = Api_Record()
        record.playlist = playlist

        var response = Api_SyncUpdateResponse()
        response.records = [record]

        syncTask.processServerData(response: response)

        // Missing episode should be added
        let added = dataManager.findEpisode(uuid: "miss-2")
        XCTAssertNotNil(added)
        XCTAssertEqual(added?.podcastUuid, "p2")
        XCTAssertEqual(added?.title, "Missing from DB")
        XCTAssertEqual(added?.downloadUrl, "http://example.com/missing.mp3")
        XCTAssertEqual(added?.addedDate?.timeIntervalSince1970, 456_000)
    }
}
