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

    func testDistinctPodcastsReturnsOrderedResultsWithLimit() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteValidator.SQLiteError.failedNewTestDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dataManager = DataManager(dbQueue: queue)

        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = "playlist-distinct"
        playlist.playlistName = "Manual Playlist"
        dataManager.save(playlist: playlist)

        let podcastA = makePodcast(uuid: "pod-a", title: "A")
        dataManager.save(podcast: podcastA)
        let podcastB = makePodcast(uuid: "pod-b", title: "B")
        dataManager.save(podcast: podcastB)
        let podcastC = makePodcast(uuid: "pod-c", title: "C")
        dataManager.save(podcast: podcastC)

        XCTAssertNotEqual(podcastA.id, 0)
        XCTAssertNotEqual(podcastB.id, 0)
        XCTAssertNotEqual(podcastC.id, 0)

        let episode1 = makeEpisode(uuid: "ep-1", podcast: podcastA)
        let episode2 = makeEpisode(uuid: "ep-2", podcast: podcastB)
        let episode3 = makeEpisode(uuid: "ep-3", podcast: podcastC)

        dataManager.save(episode: episode1)
        dataManager.save(episode: episode2)
        dataManager.save(episode: episode3)

        dataManager.add(episodes: [episode1, episode2, episode3], to: playlist)

        let limited = dataManager.distinctPodcasts(for: playlist, limit: 2, shouldShowArchived: false)
        XCTAssertEqual(limited.map(\.uuid), [episode1.uuid, episode2.uuid])
        XCTAssertEqual(limited.map(\.podcastUuid), [podcastA.uuid, podcastB.uuid])

        let unlimited = dataManager.distinctPodcasts(for: playlist, limit: 0, shouldShowArchived: false)
        XCTAssertEqual(unlimited.map(\.uuid), [episode1.uuid, episode2.uuid, episode3.uuid])
        XCTAssertEqual(unlimited.map(\.podcastUuid), [podcastA.uuid, podcastB.uuid, podcastC.uuid])
    }

    func testDistinctPodcastsHonorsArchivedFlag() throws {
        guard let dbPool = try DatabasePool.newTestDatabase() else {
            throw SQLiteValidator.SQLiteError.failedNewTestDatabase
        }
        let queue = GRDBQueue(dbPool: dbPool)
        DatabaseHelper.setup(queue: queue)
        let dataManager = DataManager(dbQueue: queue)

        let playlist = EpisodeFilter()
        playlist.manual = true
        playlist.uuid = "playlist-archived"
        playlist.playlistName = "Manual Playlist"
        dataManager.save(playlist: playlist)

        let podcastA = makePodcast(uuid: "arch-a", title: "A")
        dataManager.save(podcast: podcastA)
        let podcastB = makePodcast(uuid: "arch-b", title: "B")
        dataManager.save(podcast: podcastB)
        let podcastC = makePodcast(uuid: "arch-c", title: "C")
        dataManager.save(podcast: podcastC)

        XCTAssertNotEqual(podcastA.id, 0)
        XCTAssertNotEqual(podcastB.id, 0)
        XCTAssertNotEqual(podcastC.id, 0)

        let episode1 = makeEpisode(uuid: "arch-ep-1", podcast: podcastA)
        let episode2 = makeEpisode(uuid: "arch-ep-2", podcast: podcastB)
        let archivedEpisode = makeEpisode(uuid: "arch-ep-3", podcast: podcastC, archived: true)

        dataManager.save(episode: episode1)
        dataManager.save(episode: episode2)
        dataManager.save(episode: archivedEpisode)

        dataManager.add(episodes: [episode1, episode2, archivedEpisode], to: playlist)

        let withoutArchived = dataManager.distinctPodcasts(for: playlist, limit: 0, shouldShowArchived: false)
        XCTAssertEqual(withoutArchived.map(\.uuid), [episode1.uuid, episode2.uuid])

        let withArchived = dataManager.distinctPodcasts(for: playlist, limit: 0, shouldShowArchived: true)
        XCTAssertEqual(withArchived.map(\.uuid), [episode1.uuid, episode2.uuid, archivedEpisode.uuid])
    }

    // MARK: - Helpers

    private func makePodcast(uuid: String, title: String) -> Podcast {
        let podcast = Podcast()
        podcast.uuid = uuid
        podcast.title = title
        return podcast
    }

    private func makeEpisode(uuid: String, podcast: Podcast, archived: Bool = false) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.title = "Episode \(uuid)"
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.duration = 60
        episode.archived = archived
        if archived {
            episode.lastArchiveInteractionDate = Date()
        }
        return episode
    }
}
