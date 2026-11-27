import XCTest
@testable import podcasts
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class PlaylistMetadataLoaderTests: DBTestCase {
    override func tearDown() async throws {
        FeatureFlagOverrideStore().resetOverrides()
        try await super.tearDown()
    }

    func testLoadsTheSameCountsAndArtworkWithAndWithoutTheFlag() async throws {
        let playlists = makeLibrary()

        let before = try await load(playlists, flag: false)
        let after = try await load(playlists, flag: true)

        XCTAssertEqual(before.counts, after.counts)
        XCTAssertEqual(before.images, after.images)
        XCTAssertEqual(after.counts, playlists.map { dataManager.allPlaylistEpisodeCount(for: $0, episodeUuidToAdd: nil, includingArchivedEpisodes: $0.manual) })
    }

    private func load(_ playlists: [EpisodeFilter], flag: Bool) async throws -> (counts: [Int], images: [[String]]) {
        try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: flag)
        let loader = PlaylistMetadataLoader(dataManager: dataManager)

        return await withTaskGroup(of: (Int, Int, [String]).self) { group in
            for (index, playlist) in playlists.enumerated() {
                group.addTask {
                    async let count = loader.loadCount(for: playlist)
                    async let images = loader.loadImages(for: playlist)
                    return await (index, count, images.map(\.id))
                }
            }
            var counts = [Int](repeating: -1, count: playlists.count)
            var images = [[String]](repeating: [], count: playlists.count)
            for await (index, count, ids) in group {
                counts[index] = count
                images[index] = ids
            }
            return (counts, images)
        }
    }

    private func makeLibrary() -> [EpisodeFilter] {
        let podcasts = (0..<6).map { index in
            let podcast = Podcast()
            podcast.uuid = "loader-podcast-\(index)"
            podcast.subscribed = 1
            podcast.addedDate = Date()
            dataManager.save(podcast: podcast)
            return podcast
        }

        let now = Date()
        for index in 0..<120 {
            let podcast = podcasts[index % podcasts.count]
            let episode = Episode()
            episode.uuid = "loader-episode-\(index)"
            episode.podcastUuid = podcast.uuid
            episode.podcast_id = podcast.id
            episode.addedDate = now.addingTimeInterval(-Double(index) * 60)
            episode.publishedDate = now.addingTimeInterval(-Double(index) * 3600)
            episode.playingStatus = [PlayingStatus.notPlayed, .inProgress, .completed][index % 3].rawValue
            episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
            episode.keepEpisode = index % 4 == 0
            dataManager.save(episode: episode)
        }

        let everything = EpisodeFilter.makeDefault()
        let inProgress = EpisodeFilter.makeDefault()
        inProgress.filterUnplayed = false
        inProgress.filterFinished = false
        let starred = EpisodeFilter.makeDefault()
        starred.filterStarred = true
        let unplayedOldest = EpisodeFilter.makeDefault()
        unplayedOldest.filterPartiallyPlayed = false
        unplayedOldest.filterFinished = false
        unplayedOldest.sortType = PlaylistSort.oldestToNewest.rawValue
        let manual = EpisodeFilter.makeDefault()
        manual.manual = true
        manual.sortType = PlaylistSort.dragAndDrop.rawValue

        let playlists = [everything, inProgress, starred, unplayedOldest, manual]
        for playlist in playlists {
            dataManager.save(playlist: playlist)
        }
        let manualEpisodes = (0..<10).compactMap { dataManager.findEpisode(uuid: "loader-episode-\($0 * 3)") }
        dataManager.add(episodes: manualEpisodes, to: manual)
        return playlists
    }
}
