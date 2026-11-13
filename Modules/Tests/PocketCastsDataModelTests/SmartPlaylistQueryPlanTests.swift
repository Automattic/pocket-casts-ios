@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import GRDB
import XCTest

final class SmartPlaylistQueryPlanTests: DataManagerTestCase {
    private var originalDataManager: DataManager!
    private var dataManager: DataManager!
    private var podcasts: [Podcast] = []
    private var unsubscribedPodcast: Podcast!
    private var episodes: [Episode] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        FeatureFlagOverrideStore().resetOverrides()
        originalDataManager = DataManager.shared
        dataManager = DataManager.newTestDataManager()
        DataManager.shared = dataManager
        insertLibrary()
    }

    override func tearDownWithError() throws {
        FeatureFlagOverrideStore().resetOverrides()
        DataManager.shared = originalDataManager
        originalDataManager = nil
        dataManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Same results

    func testCountsMatchWithAndWithoutTheFlag() throws {
        for (name, playlist) in smartPlaylists() {
            let before = try counts(for: playlist, flag: false)
            let after = try counts(for: playlist, flag: true)
            XCTAssertEqual(before, after, name)
        }
    }

    func testFirstDistinctEpisodesMatchWithAndWithoutTheFlag() throws {
        for (name, playlist) in smartPlaylists() {
            let before = try firstDistinctEpisodes(for: playlist, flag: false)
            let after = try firstDistinctEpisodes(for: playlist, flag: true)
            XCTAssertEqual(before, after, name)
        }
    }

    func testTheRulesMatchEpisodes() throws {
        for (name, playlist) in smartPlaylists() {
            let count = try counts(for: playlist, flag: true)[0]
            XCTAssertGreaterThan(count, 0, name)
            XCTAssertFalse(try firstDistinctEpisodes(for: playlist, flag: true).isEmpty, name)
        }
    }

    func testCountsSkipDuplicateEpisodes() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: true)
        let query = "SELECT COUNT(*) FROM SJEpisode WHERE archived = 0 AND podcast_id <> ?"

        let allRows = dataManager.count(query: query, values: [unsubscribedPodcast.id])
        XCTAssertEqual(dataManager.allPlaylistEpisodeCount(for: EpisodeFilter.makeDefault(), episodeUuidToAdd: nil), allRows - 2)

        let inProgressRows = dataManager.count(query: query + " AND playingStatus = ?", values: [unsubscribedPodcast.id, PlayingStatus.inProgress.rawValue])
        XCTAssertEqual(dataManager.allPlaylistEpisodeCount(for: inProgress(), episodeUuidToAdd: nil), inProgressRows - 1)
    }

    // MARK: - Query plans

    func testCountsNeitherWalkTheUuidIndexNorSortTheEpisodes() throws {
        let unplayed = EpisodeFilter.makeDefault()
        unplayed.filterPartiallyPlayed = false
        unplayed.filterFinished = false

        for playlist in [inProgress(), unplayed] {
            try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: false)
            XCTAssertTrue(try plan(PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: playlist)).contains("SCAN episode USING INDEX episode_uuid"))

            try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: true)
            for clause in [PlaylistQueryBuilder.SelectClause.allEpisodeCount, .episodeCount] {
                let plan = try plan(PlaylistQueryBuilder.query(clause: clause, for: playlist))
                XCTAssertFalse(plan.contains("SCAN episode USING INDEX episode_uuid"), plan)
                XCTAssertFalse(plan.contains("ORDER BY"), plan)
            }
        }
    }

    func testFirstDistinctEpisodesReadTheTableForInProgressAndStarred() throws {
        let starred = EpisodeFilter.makeDefault()
        starred.filterStarred = true

        for playlist in [inProgress(), starred] {
            let query = { PlaylistQueryBuilder.query(clause: .firstDistinctEpisodes, for: playlist, limit: 4) }

            try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: false)
            XCTAssertTrue(try plan(query()).contains("SCAN episode USING INDEX episode_pub_date"))

            try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: true)
            XCTAssertFalse(try plan(query()).contains("USING INDEX episode_pub_date"))
        }
    }

    func testFirstDistinctEpisodesKeepThePublishedDateIndexForUnplayedAndRecentEpisodes() throws {
        try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: true)

        let unplayed = EpisodeFilter.makeDefault()
        unplayed.filterPartiallyPlayed = false
        unplayed.filterFinished = false
        XCTAssertTrue(try plan(PlaylistQueryBuilder.query(clause: .firstDistinctEpisodes, for: unplayed, limit: 4)).contains("SCAN episode USING INDEX episode_pub_date"))

        let recentInProgress = inProgress()
        recentInProgress.filterHours = 24 * 31
        XCTAssertTrue(try plan(PlaylistQueryBuilder.query(clause: .firstDistinctEpisodes, for: recentInProgress, limit: 4)).contains("SEARCH episode USING INDEX episode_pub_date (publishedDate>?)"))
    }

    // MARK: - Helpers

    private func counts(for playlist: EpisodeFilter, flag: Bool) throws -> [Int] {
        try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: flag)
        let added = episodes[9].uuid
        return [
            dataManager.allPlaylistEpisodeCount(for: playlist, episodeUuidToAdd: nil),
            dataManager.allPlaylistEpisodeCount(for: playlist, episodeUuidToAdd: nil, includingArchivedEpisodes: true),
            dataManager.allPlaylistEpisodeCount(for: playlist, episodeUuidToAdd: added),
            dataManager.playlistEpisodeCount(for: playlist, episodeUuidToAdd: nil),
            dataManager.playlistArchivedEpisodeCount(for: playlist, episodeUuidToAdd: nil)
        ]
    }

    private func firstDistinctEpisodes(for playlist: EpisodeFilter, flag: Bool) throws -> [String] {
        try FeatureFlagOverrideStore().override(FeatureFlag.efficientPlaylistQueries, withValue: flag)
        let query = PlaylistQueryBuilder.query(clause: .firstDistinctEpisodes, for: playlist, limit: 4)
        return dataManager.findPlaylistEpisodesWhere(query: query, arguments: nil).map { "\($0.uuid) \($0.id)" }
    }

    private func plan(_ query: String) throws -> String {
        try dataManager.dbQueue.dbPool.read { db in
            try Row.fetchAll(db, sql: "EXPLAIN QUERY PLAN " + query).map { $0["detail"] as String }.joined(separator: "\n")
        }
    }

    private func inProgress() -> EpisodeFilter {
        let playlist = EpisodeFilter.makeDefault()
        playlist.filterUnplayed = false
        playlist.filterFinished = false
        return playlist
    }

    private func smartPlaylists() -> [(String, EpisodeFilter)] {
        var playlists: [(String, EpisodeFilter)] = []
        func add(_ name: String, _ configure: (EpisodeFilter) -> Void) {
            for sortType in [PlaylistSort.newestToOldest, .oldestToNewest, .shortestToLongest, .longestToShortest] {
                let playlist = EpisodeFilter.makeDefault()
                playlist.sortType = sortType.rawValue
                configure(playlist)
                playlists.append(("\(name), sort \(sortType)", playlist))
            }
        }
        add("everything") { _ in }
        add("unplayed") { $0.filterPartiallyPlayed = false; $0.filterFinished = false }
        add("in progress") { $0.filterUnplayed = false; $0.filterFinished = false }
        add("played") { $0.filterUnplayed = false; $0.filterPartiallyPlayed = false }
        add("in progress and played") { $0.filterUnplayed = false }
        add("unplayed and in progress, recent") { $0.filterFinished = false; $0.filterHours = 24 * 14 }
        add("in progress, recent") { $0.filterUnplayed = false; $0.filterFinished = false; $0.filterHours = 24 * 31 }
        add("starred") { $0.filterStarred = true }
        add("starred and played") { $0.filterStarred = true; $0.filterUnplayed = false; $0.filterPartiallyPlayed = false }
        add("downloaded") { $0.filterNotDownloaded = false }
        add("not downloaded") { $0.filterDownloaded = false }
        add("video") { $0.filterAudioVideoType = AudioVideoFilter.videoOnly.rawValue }
        add("audio, in progress") { $0.filterAudioVideoType = AudioVideoFilter.audioOnly.rawValue; $0.filterUnplayed = false; $0.filterFinished = false }
        add("duration") { $0.filterDuration = true; $0.longerThan = 10; $0.shorterThan = 40 }
        add("two podcasts") { [podcasts] in $0.filterAllPodcasts = false; $0.podcastUuids = "\(podcasts[0].uuid),\(podcasts[2].uuid)" }
        add("two podcasts, in progress") { [podcasts] in $0.filterAllPodcasts = false; $0.podcastUuids = "\(podcasts[1].uuid),\(podcasts[3].uuid)"; $0.filterUnplayed = false; $0.filterFinished = false }
        return playlists
    }

    /// 5 podcasts (one unsubscribed) with 300 episodes that cover every play, download, starred, archived, media type
    /// and duration combination, with distinct dates, plus three episodes (one archived) saved twice under the same UUID.
    private func insertLibrary() {
        podcasts = (0..<5).map { index in
            createTestPodcast(uuid: "podcast-\(index)", title: "Podcast \(index)", subscribed: index == 4 ? 0 : 1, dataManager: dataManager)
        }
        unsubscribedPodcast = podcasts.removeLast()
        let allPodcasts = podcasts + [unsubscribedPodcast!]

        let now = Date().timeIntervalSince1970
        let downloadStatuses: [DownloadStatus] = [.notDownloaded, .queued, .downloading, .downloadFailed, .downloaded, .waitingForWifi]
        let playingStatuses: [PlayingStatus] = [.notPlayed, .inProgress, .completed]
        for index in 0..<300 {
            let podcast = allPodcasts[(index * 7) % allPodcasts.count]
            let episode = Episode()
            episode.uuid = "episode-\(index)"
            episode.podcastUuid = podcast.uuid
            episode.podcast_id = podcast.id
            episode.title = "Episode \(index)"
            episode.publishedDate = Date(timeIntervalSince1970: now - Double(index) * 3 * 3600)
            episode.addedDate = Date(timeIntervalSince1970: now - Double(index) * 60)
            episode.playingStatus = playingStatuses[(index / 2) % playingStatuses.count].rawValue
            episode.episodeStatus = downloadStatuses[index % downloadStatuses.count].rawValue
            episode.keepEpisode = index % 5 == 0
            episode.archived = index % 11 == 0
            episode.fileType = index % 4 == 0 ? "video/mp4" : "audio/mp3"
            episode.duration = Double((index % 9) * 600)
            dataManager.save(episode: episode)
            episodes.append(episode)
        }

        for original in [episodes[3], episodes[6], episodes[11]] {
            let duplicate = Episode()
            duplicate.uuid = original.uuid
            duplicate.podcastUuid = original.podcastUuid
            duplicate.podcast_id = original.podcast_id
            duplicate.title = original.title
            duplicate.publishedDate = original.publishedDate
            duplicate.addedDate = original.addedDate.map { $0.addingTimeInterval(1) }
            duplicate.playingStatus = original.playingStatus
            duplicate.episodeStatus = DownloadStatus.notDownloaded.rawValue
            duplicate.keepEpisode = original.keepEpisode
            duplicate.archived = original.archived
            duplicate.fileType = original.fileType
            duplicate.duration = original.duration
            dataManager.save(episode: duplicate)
        }
    }
}
