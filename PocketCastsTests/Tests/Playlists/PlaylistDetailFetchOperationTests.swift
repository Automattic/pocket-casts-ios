import XCTest
@testable import podcasts
@testable import PocketCastsDataModel

final class PlaylistDetailFetchOperationTests: DBTestCase {
    func testSmartPlaylistWithEpisodesSkipsTheArchivedCount() async throws {
        let (podcast, _) = makePodcast(unarchived: 3, archived: 2)

        let (episodes, archivedCount) = await fetch(smartPlaylist(for: podcast))

        XCTAssertEqual(episodes.count, 3)
        XCTAssertEqual(archivedCount, 0)
    }

    func testSmartPlaylistWithOnlyArchivedEpisodesCountsThem() async throws {
        let (podcast, _) = makePodcast(unarchived: 0, archived: 2)

        let (episodes, archivedCount) = await fetch(smartPlaylist(for: podcast))

        XCTAssertTrue(episodes.isEmpty)
        XCTAssertEqual(archivedCount, 2)
    }

    func testManualPlaylistCountsArchivedEpisodes() async throws {
        let (_, podcastEpisodes) = makePodcast(unarchived: 3, archived: 2)
        let playlist = EpisodeFilter.makeDefault()
        playlist.manual = true
        playlist.sortType = PlaylistSort.dragAndDrop.rawValue
        dataManager.save(playlist: playlist)
        dataManager.add(episodes: podcastEpisodes, to: playlist)

        let (episodes, archivedCount) = await fetch(playlist)

        XCTAssertEqual(episodes.count, 3)
        XCTAssertEqual(archivedCount, 2)
    }

    // MARK: - Helpers

    private func fetch(_ playlist: EpisodeFilter) async -> (episodes: [ListEpisode], archivedCount: Int) {
        let fetched = expectation(description: "fetched")
        var result: ([ListEpisode], Int) = ([], -1)
        let operation = PlaylistDetailFetchOperation(dataManager: dataManager, playlist: playlist, shouldShowArchived: playlist.showArchivedEpisodes) { episodes, archivedCount in
            result = (episodes, archivedCount)
            fetched.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        await fulfillment(of: [fetched], timeout: 10)
        return result
    }

    private func smartPlaylist(for podcast: Podcast) -> EpisodeFilter {
        let playlist = EpisodeFilter.makeDefault()
        playlist.filterAllPodcasts = false
        playlist.podcastUuids = podcast.uuid
        dataManager.save(playlist: playlist)
        return playlist
    }

    private func makePodcast(unarchived: Int, archived: Int) -> (Podcast, [Episode]) {
        let podcast = Podcast()
        podcast.uuid = UUID().uuidString
        podcast.subscribed = 1
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)

        let episodes = (0..<(unarchived + archived)).map { index in
            let episode = Episode()
            episode.uuid = UUID().uuidString
            episode.podcastUuid = podcast.uuid
            episode.podcast_id = podcast.id
            episode.addedDate = Date()
            episode.publishedDate = Date().addingTimeInterval(-Double(index) * 3600)
            episode.playingStatus = PlayingStatus.notPlayed.rawValue
            episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
            episode.archived = index >= unarchived
            dataManager.save(episode: episode)
            return episode
        }
        return (podcast, episodes)
    }
}
