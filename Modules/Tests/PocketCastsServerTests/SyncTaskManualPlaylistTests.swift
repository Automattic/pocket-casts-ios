@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
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
        DataManager.shared = dataManager
    }

    override func tearDown() {
        FeatureFlagMock().reset()
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

    func testManualPlaylistSyncOverridesSortTypeToDragAndDrop() {
        // Seed episodes that would be sorted differently if playlist.sortType was honored
        let older = Episode()
        older.uuid = "manual-old"
        older.podcastUuid = "pod-old"
        older.podcast_id = 1
        older.title = "Old Episode"
        older.downloadUrl = "http://example.com/old.mp3"
        older.addedDate = Date(timeIntervalSince1970: 1)
        older.publishedDate = Date(timeIntervalSince1970: 1)
        dataManager.save(episode: older)

        let newer = Episode()
        newer.uuid = "manual-new"
        newer.podcastUuid = "pod-new"
        newer.podcast_id = 2
        newer.title = "New Episode"
        newer.downloadUrl = "http://example.com/new.mp3"
        newer.addedDate = Date(timeIntervalSince1970: 2)
        newer.publishedDate = Date(timeIntervalSince1970: 2)
        dataManager.save(episode: newer)

        let playlist = EpisodeFilter()
        playlist.uuid = "manual-sort-override"
        playlist.playlistName = "Manual Needs Override"
        playlist.manual = true
        playlist.sortType = PlaylistSort.newestToOldest.rawValue
        playlist.syncStatus = SyncStatus.notSynced.rawValue
        dataManager.save(playlist: playlist)
        dataManager.add(episodes: [older, newer], to: playlist)

        let records = syncTask.changedPlaylists()
        let playlistRecords = records?.compactMap { $0.record }.compactMap { record -> Api_SyncUserPlaylist? in
            if case let .playlist(p) = record { return p }
            return nil
        }

        let syncedPlaylist = try! XCTUnwrap(playlistRecords?.first)
        XCTAssertEqual(syncedPlaylist.sortType.value, PlaylistSort.newestToOldest.rawValue)
        XCTAssertEqual(syncedPlaylist.episodeOrder, [older.uuid, newer.uuid])
        XCTAssertEqual(syncedPlaylist.episodes.map(\.episode), [older.uuid, newer.uuid])
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
        FailingURLProtocol.requestCount = 0
        URLProtocol.registerClass(FailingURLProtocol.self)
        defer { URLProtocol.unregisterClass(FailingURLProtocol.self) }

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
        XCTAssertTrue(added?.wasDeleted ?? false)

        let persistedExisting = dataManager.findEpisode(uuid: existing.uuid)
        XCTAssertNotNil(persistedExisting)
        XCTAssertFalse(persistedExisting?.wasDeleted ?? true)

        XCTAssertGreaterThanOrEqual(FailingURLProtocol.requestCount, 1)
    }

    func testProcessServerDataImportsMultipleEpisodesFromUnloadedPodcast() throws {
        let podcastUuid = "unloaded-pod-\(UUID().uuidString)"
        let ep1Uuid = "ep-1-\(UUID().uuidString)"
        let ep2Uuid = "ep-2-\(UUID().uuidString)"
        let missingEpUuid = "ep-missing-\(UUID().uuidString)"

        MockFindByEpisodeURLProtocol.handler = { request in
            guard let url = request.url?.absoluteString else { return nil }
            if url.contains("/\(podcastUuid)/\(ep1Uuid)") {
                return [
                    "podcast": [
                        "uuid": podcastUuid,
                        "title": "Unloaded Podcast",
                        "episodes": [
                            [
                                "uuid": ep1Uuid,
                                "title": "Server Episode 1",
                                "url": "https://example.com/1.mp3",
                                "file_type": "audio/mp3",
                                "file_size": 1000,
                                "duration": 300.0,
                                "published": "2026-01-01T00:00:00Z"
                            ]
                        ]
                    ]
                ]
            } else if url.contains("/\(podcastUuid)/\(ep2Uuid)") {
                return [
                    "podcast": [
                        "uuid": podcastUuid,
                        "title": "Unloaded Podcast",
                        "episodes": [
                            [
                                "uuid": ep2Uuid,
                                "title": "Server Episode 2",
                                "url": "https://example.com/2.mp3",
                                "file_type": "audio/mp3",
                                "file_size": 2000,
                                "duration": 600.0,
                                "published": "2026-01-02T00:00:00Z"
                            ]
                        ]
                    ]
                ]
            }
            return nil
        }
        URLProtocol.registerClass(MockFindByEpisodeURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(MockFindByEpisodeURLProtocol.self)
            MockFindByEpisodeURLProtocol.handler = nil
        }

        var playlist = Api_SyncUserPlaylist()
        playlist.originalUuid = "manual-pl-\(UUID().uuidString)"
        playlist.uuid = playlist.originalUuid
        playlist.title.value = "Web Manual Playlist"
        playlist.manual = true
        playlist.episodeOrder = [ep1Uuid, ep2Uuid, missingEpUuid]
        playlist.episodes = [ep1Uuid, ep2Uuid, missingEpUuid].enumerated().map { index, epUuid in
            var p = Api_SyncPlaylistEpisode()
            p.episode = epUuid
            p.podcast = podcastUuid
            p.title.value = "Placeholder \(index + 1)"
            p.url.value = "https://example.com/placeholder-\(index + 1).mp3"
            p.added = Google_Protobuf_Int64Value(Int64(100_000 + index))
            return p
        }

        var record = Api_Record()
        record.playlist = playlist

        var response = Api_SyncUpdateResponse()
        response.records = [record]

        syncTask.processServerData(response: response)

        let podcast = try XCTUnwrap(dataManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true))

        // Both available episodes should be recovered with no duplicate rows
        for (uuid, expectedTitle, expectedDuration) in [(ep1Uuid, "Server Episode 1", 300.0), (ep2Uuid, "Server Episode 2", 600.0)] {
            let rows = dataManager.findEpisodesWhere(customWhere: "uuid = ?", arguments: [uuid])
            XCTAssertEqual(rows.count, 1, "Expected single SJEpisode row for \(uuid)")
            let episode = try XCTUnwrap(rows.first)
            XCTAssertFalse(episode.wasDeleted, "Episode \(uuid) should not remain wasDeleted")
            XCTAssertEqual(episode.podcast_id, podcast.id)
            XCTAssertEqual(episode.episodeStatus, DownloadStatus.notDownloaded.rawValue)
            XCTAssertEqual(episode.playingStatus, PlayingStatus.notPlayed.rawValue)
            XCTAssertEqual(episode.title, expectedTitle)
            XCTAssertEqual(episode.duration, expectedDuration)
            XCTAssertEqual(episode.fileType, "audio/mp3")
        }

        // Both available episodes appear in the podcast's episode list; genuinely unavailable one does not
        let podcastEpisodes = dataManager.allEpisodes(forPodcastId: podcast.id)
        XCTAssertEqual(Set(podcastEpisodes.map(\.uuid)), Set([ep1Uuid, ep2Uuid]))

        // Genuinely missing episode stays unavailable
        let missingEpisode = try XCTUnwrap(dataManager.findEpisode(uuid: missingEpUuid))
        XCTAssertTrue(missingEpisode.wasDeleted)
    }
}

private final class FailingURLProtocol: URLProtocol {
    static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        FailingURLProtocol.requestCount += 1
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}

private final class MockFindByEpisodeURLProtocol: URLProtocol {
    static var handler: ((URLRequest) -> [String: Any]?)?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let json = Self.handler?(request),
              let data = try? JSONSerialization.data(withJSONObject: json),
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
