import XCTest
import PocketCastsDataModel
@testable import podcasts

final class PlaylistManagerAutoDownloadTests: DBTestCase {
    func testQueuesEpisodeAddedToManualPlaylist() throws {
        let playlist = makeManualPlaylist(autoDownload: true)
        let episode = makeEpisode()
        dataManager.add(episodes: [episode], to: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: false, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertEqual(queued, [episode.uuid])
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.episodeStatus, DownloadStatus.waitingForWifi.rawValue)
        XCTAssertEqual(refreshed.autoDownloadStatus, AutoDownloadStatus.autoDownloaded.rawValue)
    }

    func testDownloadsImmediatelyWhenConnectionAllowsIt() throws {
        let playlist = makeManualPlaylist(autoDownload: true)
        let episode = makeEpisode()
        dataManager.add(episodes: [episode], to: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: true, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertEqual(queued, [episode.uuid])
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.episodeStatus, DownloadStatus.queued.rawValue)
        XCTAssertEqual(refreshed.autoDownloadStatus, AutoDownloadStatus.autoDownloaded.rawValue)
    }

    func testIgnoresManualPlaylistWithAutoDownloadOff() throws {
        let playlist = makeManualPlaylist(autoDownload: false)
        let episode = makeEpisode()
        dataManager.add(episodes: [episode], to: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: false, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertTrue(queued.isEmpty)
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.episodeStatus, DownloadStatus.notDownloaded.rawValue)
        XCTAssertEqual(refreshed.autoDownloadStatus, AutoDownloadStatus.notSpecified.rawValue)
    }

    /// Turning auto download on for a playlist that already has episodes should download them,
    /// not just the ones added afterwards.
    func testQueuesEpisodesAlreadyInThePlaylist() throws {
        let playlist = makeManualPlaylist(autoDownload: false)
        let episode = makeEpisode()
        dataManager.add(episodes: [episode], to: playlist)

        playlist.autoDownloadEpisodes = true
        dataManager.save(playlist: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: false, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertEqual(queued, [episode.uuid])
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.episodeStatus, DownloadStatus.waitingForWifi.rawValue)
    }

    func testSkipsEpisodesAlreadyQueued() throws {
        let playlist = makeManualPlaylist(autoDownload: true)
        let episode = makeEpisode(status: .queued)
        dataManager.add(episodes: [episode], to: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: false, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertTrue(queued.isEmpty)
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.autoDownloadStatus, AutoDownloadStatus.notSpecified.rawValue)
    }

    func testSkipsEpisodesAlreadyDownloaded() throws {
        let playlist = makeManualPlaylist(autoDownload: true)
        let episode = makeEpisode(status: .downloaded)
        createDownloadedFile(for: episode)
        dataManager.add(episodes: [episode], to: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: false, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertTrue(queued.isEmpty)
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.episodeStatus, DownloadStatus.downloaded.rawValue)
    }

    func testRespectsTheAutoDownloadLimit() throws {
        let playlist = makeManualPlaylist(autoDownload: true)
        playlist.autoDownloadLimit = 1
        dataManager.save(playlist: playlist)

        let episodes = [makeEpisode(), makeEpisode()]
        dataManager.add(episodes: episodes, to: playlist)

        let queued = PlaylistManager.queueAutoDownloads(for: playlist, downloadsAllowedNow: false, dataManager: dataManager, downloadManager: downloadManager)

        XCTAssertEqual(queued.count, 1)
    }

    func testCheckForAutoDownloadsInPlaylistQueuesAndNotifies() throws {
        let playlist = makeManualPlaylist(autoDownload: true)
        let episode = makeEpisode()
        dataManager.add(episodes: [episode], to: playlist)

        let notified = expectation(forNotification: Constants.Notifications.manyEpisodesChanged, object: nil)

        PlaylistManager.checkForAutoDownloads(in: playlist)

        wait(for: [notified], timeout: 5)
        let refreshed = try XCTUnwrap(dataManager.findEpisode(uuid: episode.uuid))
        XCTAssertEqual(refreshed.autoDownloadStatus, AutoDownloadStatus.autoDownloaded.rawValue)
        XCTAssertNotEqual(refreshed.episodeStatus, DownloadStatus.notDownloaded.rawValue)
    }

    // MARK: - Helpers

    private func makeManualPlaylist(autoDownload: Bool) -> EpisodeFilter {
        let playlist = EpisodeFilter.makeDefault()
        playlist.playlistName = "Manual Playlist"
        playlist.manual = true
        playlist.sortType = PlaylistSort.dragAndDrop.rawValue
        playlist.autoDownloadEpisodes = autoDownload
        dataManager.save(playlist: playlist)

        return playlist
    }

    private func makeEpisode(status: DownloadStatus = .notDownloaded) -> Episode {
        let episode = Episode()
        episode.uuid = UUID().uuidString
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.addedDate = Date()
        episode.publishedDate = Date()
        episode.downloadUrl = "http://example.com/audio"
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = status.rawValue
        dataManager.save(episode: episode)

        return episode
    }

    private func createDownloadedFile(for episode: Episode) {
        let path = downloadManager.pathForEpisode(episode)
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: path, contents: Data())
    }
}
