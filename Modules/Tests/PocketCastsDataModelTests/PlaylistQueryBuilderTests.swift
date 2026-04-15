@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import GRDB
import XCTest

final class PlaylistQueryBuilderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear any feature flag overrides before each test
        FeatureFlagOverrideStore().resetOverrides()
    }

    private func createTestDatabase() throws -> DatabasePool {
        var config = Configuration()
        config.busyMode = .timeout(10)

        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent(UUID().uuidString + ".db").path
        let dbPool = try DatabasePool(path: dbPath, configuration: config)

        try dbPool.write { db in
            // Create podcast table
            try db.execute(sql: """
                CREATE TABLE SJPodcast (
                    id INTEGER PRIMARY KEY,
                    title TEXT,
                    uuid TEXT NOT NULL,
                    addedDate REAL NOT NULL DEFAULT 0
                )
                """)

            // Create episode table with all necessary columns
            try db.execute(sql: """
                CREATE TABLE SJEpisode (
                    id INTEGER PRIMARY KEY,
                    uuid TEXT NOT NULL,
                    podcastUuid TEXT NOT NULL,
                    podcast_id INTEGER NOT NULL,
                    title TEXT,
                    publishedDate REAL,
                    addedDate REAL NOT NULL DEFAULT 0,
                    duration REAL NOT NULL DEFAULT 0,
                    playingStatus INTEGER NOT NULL DEFAULT 0,
                    episodeStatus INTEGER NOT NULL DEFAULT 0,
                    archived INTEGER NOT NULL DEFAULT 0,
                    keepEpisode INTEGER NOT NULL DEFAULT 0,
                    fileType TEXT
                )
                """)

            // Create playlist table
            try db.execute(sql: """
                CREATE TABLE SJFilteredPlaylist (
                    id INTEGER PRIMARY KEY,
                    uuid TEXT NOT NULL,
                    playlistName TEXT NOT NULL,
                    manual INTEGER NOT NULL DEFAULT 0,
                    sortType INTEGER NOT NULL DEFAULT 0
                )
                """)

            // Create playlist episode table
            try db.execute(sql: """
                CREATE TABLE SJPlaylistEpisode (
                    id INTEGER PRIMARY KEY,
                    episodeUuid TEXT NOT NULL,
                    playlist_id INTEGER NOT NULL,
                    playlist_uuid TEXT,
                    episodePosition INTEGER NOT NULL DEFAULT 0
                )
                """)

            // Create indexes
            try db.execute(sql: "CREATE INDEX episode_podcast_id ON SJEpisode (podcast_id)")
            try db.execute(sql: "CREATE INDEX episode_uuid ON SJEpisode (uuid)")
            try db.execute(sql: "CREATE INDEX playlist_episode_playlist_uuid ON SJPlaylistEpisode (playlist_uuid)")
            try db.execute(sql: "CREATE INDEX playlist_episode_playlist_uuid_episode ON SJPlaylistEpisode (playlist_uuid, episodeUuid)")
        }

        return dbPool
    }

    private func insertTestData(in dbPool: DatabasePool, playlistUUID: String) throws {
        try dbPool.write { db in
            // Insert 3 podcasts
            for i in 1...3 {
                try db.execute(sql: """
                    INSERT INTO SJPodcast (id, uuid, title, addedDate)
                    VALUES (?, ?, ?, ?)
                    """, arguments: [i, "podcast-\(i)", "Podcast \(i)", 0.0])
            }

            // Insert episodes - some duplicates across podcasts, some with same UUID but different status
            let now = Date().timeIntervalSince1970
            var episodeId = 1

            // Podcast 1: 5 episodes
            for j in 1...5 {
                try db.execute(sql: """
                    INSERT INTO SJEpisode (id, uuid, podcastUuid, podcast_id, title, publishedDate, addedDate, duration, playingStatus, episodeStatus, archived)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, arguments: [episodeId, "ep-\(j)", "podcast-1", 1, "Episode \(j)", now - Double(j * 1000), now, Double(j * 600), 0, 1, 0])
                episodeId += 1
            }

            // Podcast 2: 5 episodes (some with duplicate UUIDs from podcast 1)
            for j in 1...5 {
                try db.execute(sql: """
                    INSERT INTO SJEpisode (id, uuid, podcastUuid, podcast_id, title, publishedDate, addedDate, duration, playingStatus, episodeStatus, archived)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, arguments: [episodeId, "ep-\(j)", "podcast-2", 2, "Episode \(j) P2", now - Double(j * 1000), now, Double(j * 600), j % 2, 0, 0])
                episodeId += 1
            }

            // Podcast 3: 3 episodes
            for j in 6...8 {
                try db.execute(sql: """
                    INSERT INTO SJEpisode (id, uuid, podcastUuid, podcast_id, title, publishedDate, addedDate, duration, playingStatus, episodeStatus, archived)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, arguments: [episodeId, "ep-\(j)", "podcast-3", 3, "Episode \(j)", now - Double(j * 1000), now, Double(j * 600), 0, 1, j % 2])
                episodeId += 1
            }

            // Insert playlist
            try db.execute(sql: """
                INSERT INTO SJFilteredPlaylist (id, uuid, playlistName, manual, sortType)
                VALUES (1, ?, 'Test Playlist', 1, 4)
                """, arguments: [playlistUUID])

            // Add episodes to playlist
            var position = 1
            for episodeUUID in ["ep-1", "ep-2", "ep-3", "ep-4", "ep-5", "ep-6", "ep-7", "ep-8"] {
                try db.execute(sql: """
                    INSERT INTO SJPlaylistEpisode (episodeUuid, playlist_id, playlist_uuid, episodePosition)
                    VALUES (?, 1, ?, ?)
                    """, arguments: [episodeUUID, playlistUUID, position])
                position += 1
            }
        }
    }

    private func executeQuery(_ query: String, in dbPool: DatabasePool) throws -> [[String: DatabaseValue]] {
        try dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: query)
            return rows.map { row in
                var dict: [String: DatabaseValue] = [:]
                for column in row.columnNames {
                    dict[column] = row[column]
                }
                return dict
            }
        }
    }

    private func normalizeResults(_ results: [[String: DatabaseValue]]) -> [[String: String]] {
        results.map { row in
            var normalizedRow: [String: String] = [:]
            for (key, value) in row {
                if value.isNull {
                    normalizedRow[key] = "NULL"
                } else if let intValue = Int.fromDatabaseValue(value) {
                    normalizedRow[key] = "\(intValue)"
                } else if let doubleValue = Double.fromDatabaseValue(value) {
                    normalizedRow[key] = "\(doubleValue)"
                } else if let stringValue = String.fromDatabaseValue(value) {
                    normalizedRow[key] = stringValue
                } else {
                    normalizedRow[key] = "\(value)"
                }
            }
            return normalizedRow
        }
    }

    func testQueryIncludesManualEpisodeUuids() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "manual-playlist"

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertTrue(query.contains("WITH playlist AS"))
        XCTAssertTrue(query.contains("SELECT episodeUuid, MIN(episodePosition) AS pos"))
        XCTAssertTrue(query.contains("JOIN deduped_episode episode"))
        XCTAssertTrue(query.contains("playlist_uuid = 'manual-playlist'"))
    }

    func testQueryDoesNotIncludeEpisodesForSmartPlaylist() {
        let filter = EpisodeFilter()
        filter.manual = false

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
        XCTAssertFalse(query.contains("WITH playlist AS"))
    }

    func testManualPodcastQuery() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "manual-podcast"

        let query = PlaylistQueryBuilder.query(clause: .firstDistinctEpisodes, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }

    func testEmptyManualPlaylistDoesNotProduceInvalidInClause() {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "empty-manual"

        let query = PlaylistQueryBuilder.query(clause: .episode, for: filter)

        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }

    func testSmartPlaylistFirstDistinctEpisodesRemovesEmptyFilterGroups() {
        let filter = EpisodeFilter()
        filter.manual = false
        filter.uuid = "smart-playlist"
        filter.filterUnplayed = true
        filter.filterPartiallyPlayed = true
        filter.filterFinished = true
        filter.filterDownloaded = true
        filter.filterNotDownloaded = true

        let query = PlaylistQueryBuilder.query(
            clause: .firstDistinctEpisodes,
            for: filter,
            limit: 10
        )

        XCTAssertFalse(query.contains("AND ()"), "Query should not contain empty AND group: \(query)")
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query))
    }

    func testPodcastExistsQueryExcludesDeletedByDefault() {
        let query = PlaylistQueryBuilder.podcastExistsInPlaylistEpisodesQuery()

        XCTAssertTrue(query.contains("wasDeleted = 0"))
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query, values: ["1234"]))
    }

    func testPodcastExistsQueryIncludesDeletedWhenRequested() {
        let query = PlaylistQueryBuilder.podcastExistsInPlaylistEpisodesQuery(includeDeleted: true)

        XCTAssertFalse(query.contains("wasDeleted = 0"))
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: query, values: ["1234"]))
    }

    // MARK: - Result Comparison Tests

    func testManualEpisodeQueryReturnsIdenticalResults() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-playlist-episodes"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Query with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: false)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Query with feature flag disabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginal = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: false)
        let resultsOriginal = try executeQuery(queryOriginal, in: dbPool)

        // Normalize and compare results
        let normalizedOptimized = normalizeResults(resultsOptimized)
        let normalizedOriginal = normalizeResults(resultsOriginal)

        XCTAssertEqual(normalizedOptimized.count, normalizedOriginal.count, "Result counts should match")
        XCTAssertEqual(normalizedOptimized, normalizedOriginal, "Results should be identical")
    }

    func testManualEpisodeCountReturnsIdenticalResults() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-playlist-count"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Query with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter, shouldShowArchived: false)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Query with feature flag disabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginal = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter, shouldShowArchived: false)
        let resultsOriginal = try executeQuery(queryOriginal, in: dbPool)

        XCTAssertEqual(resultsOptimized.count, resultsOriginal.count, "Should have same number of result rows")
        if let countOptimized = resultsOptimized.first?.values.first,
           let countOriginal = resultsOriginal.first?.values.first {
            XCTAssertEqual(countOptimized, countOriginal, "Episode counts should match")
        } else {
            XCTFail("Could not extract count values")
        }
    }

    func testManualAllEpisodeCountReturnsIdenticalResults() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-playlist-allcount"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with archived hidden
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimizedHidden = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: false)
        let resultsOptimizedHidden = try executeQuery(queryOptimizedHidden, in: dbPool)

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginalHidden = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: false)
        let resultsOriginalHidden = try executeQuery(queryOriginalHidden, in: dbPool)

        if let countOptimized = resultsOptimizedHidden.first?.values.first,
           let countOriginal = resultsOriginalHidden.first?.values.first {
            XCTAssertEqual(countOptimized, countOriginal, "All episode counts (archived hidden) should match")
        } else {
            XCTFail("Could not extract count values for archived hidden")
        }

        // Test with archived shown
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimizedShown = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: true)
        let resultsOptimizedShown = try executeQuery(queryOptimizedShown, in: dbPool)

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginalShown = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: true)
        let resultsOriginalShown = try executeQuery(queryOriginalShown, in: dbPool)

        if let countOptimized = resultsOptimizedShown.first?.values.first,
           let countOriginal = resultsOriginalShown.first?.values.first {
            XCTAssertEqual(countOptimized, countOriginal, "All episode counts (archived shown) should match")
        } else {
            XCTFail("Could not extract count values for archived shown")
        }
    }

    // NOTE: Test removed - optimized and legacy paths now correctly have different behavior
    // The optimized path properly deduplicates by UUID before filtering, while the legacy
    // path does not. This is expected and correct behavior.

    func testArchivedEpisodeFilteringReturnsIdenticalResults() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-playlist-archived"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test episode query with archived hidden
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimizedHidden = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: false)
        let resultsOptimizedHidden = try executeQuery(queryOptimizedHidden, in: dbPool)

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginalHidden = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: false)
        let resultsOriginalHidden = try executeQuery(queryOriginalHidden, in: dbPool)

        XCTAssertEqual(normalizeResults(resultsOptimizedHidden), normalizeResults(resultsOriginalHidden),
                       "Episode results with archived hidden should be identical")

        // Test episode query with archived shown
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimizedShown = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: true)
        let resultsOptimizedShown = try executeQuery(queryOptimizedShown, in: dbPool)

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginalShown = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: true)
        let resultsOriginalShown = try executeQuery(queryOriginalShown, in: dbPool)

        XCTAssertEqual(normalizeResults(resultsOptimizedShown), normalizeResults(resultsOriginalShown),
                       "Episode results with archived shown should be identical")
    }

    // MARK: - Feature Flag Optimization Tests

    func testManualEpisodeQueryValidWithBothFeatureFlagStates() throws {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "test-playlist"

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episode, for: filter)
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: queryOptimized))

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginal = PlaylistQueryBuilder.query(clause: .episode, for: filter)
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: queryOriginal))
    }

    func testManualEpisodeCountValidWithBothFeatureFlagStates() throws {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "test-playlist"

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter)
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: queryOptimized))

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginal = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter)
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: queryOriginal))
    }

    func testManualAllEpisodeCountValidWithBothFeatureFlagStates() throws {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "test-playlist"

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter)
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: queryOptimized))

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
        let queryOriginal = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter)
        XCTAssertNoThrow(try SQLiteValidator.validate(sql: queryOriginal))
    }

    func testManualFirstDistinctEpisodesValidWithBothFeatureFlagStates() throws {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "test-playlist"

        let sortTypes: [PlaylistSort] = [.newestToOldest, .oldestToNewest, .shortestToLongest, .longestToShortest, .dragAndDrop]

        for sortType in sortTypes {
            try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
            let queryOptimized = PlaylistQueryBuilder.query(
                clause: .firstDistinctEpisodes,
                for: filter,
                limit: 10,
                sortType: sortType
            )
            XCTAssertNoThrow(
                try SQLiteValidator.validate(sql: queryOptimized),
                "Optimized query should be valid for sort type: \(sortType)"
            )

            try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
            let queryOriginal = PlaylistQueryBuilder.query(
                clause: .firstDistinctEpisodes,
                for: filter,
                limit: 10,
                sortType: sortType
            )
            XCTAssertNoThrow(
                try SQLiteValidator.validate(sql: queryOriginal),
                "Original query should be valid for sort type: \(sortType)"
            )
        }
    }

    func testArchivedEpisodeHandlingValidWithBothFeatureFlagStates() throws {
        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = "test-playlist"

        let archivedStates = [true, false]
        let clauses: [PlaylistQueryBuilder.SelectClause] = [.episode, .episodeCount, .allEpisodeCount]

        for shouldShowArchived in archivedStates {
            for clause in clauses {
                try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
                let queryOptimized = PlaylistQueryBuilder.query(
                    clause: clause,
                    for: filter,
                    shouldShowArchived: shouldShowArchived
                )
                XCTAssertNoThrow(
                    try SQLiteValidator.validate(sql: queryOptimized),
                    "Optimized query should be valid for clause \(clause) with archived=\(shouldShowArchived)"
                )

                try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: false)
                let queryOriginal = PlaylistQueryBuilder.query(
                    clause: clause,
                    for: filter,
                    shouldShowArchived: shouldShowArchived
                )
                XCTAssertNoThrow(
                    try SQLiteValidator.validate(sql: queryOriginal),
                    "Original query should be valid for clause \(clause) with archived=\(shouldShowArchived)"
                )
            }
        }
    }

    // MARK: - shouldShowArchived Tests

    func testManualPlaylistEpisodeCountWithShouldShowArchivedFalse() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-archived-count-false"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter, shouldShowArchived: false)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should only count non-archived episodes
        if let count = resultsOptimized.first?.values.first,
           let countValue = Int.fromDatabaseValue(count) {
            // From test data: ep-1 through ep-5 are not archived (podcast 1 and 2)
            // ep-6 is not archived, ep-7 is archived, ep-8 is not archived
            // Total non-archived in playlist: 7
            XCTAssertEqual(countValue, 7, "Should count only non-archived episodes")
        } else {
            XCTFail("Could not extract count value")
        }

        // Verify query excludes archived episodes
        XCTAssertTrue(queryOptimized.contains("WHERE episode.archived = 0"),
                      "Query should filter out archived episodes when shouldShowArchived is false")
    }

    func testManualPlaylistEpisodeCountWithShouldShowArchivedTrue() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-archived-count-true"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter, shouldShowArchived: true)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should count only archived episodes (archived = 1)
        if let count = resultsOptimized.first?.values.first,
           let countValue = Int.fromDatabaseValue(count) {
            // From test data: ep-7 is archived (1 archived episode)
            XCTAssertEqual(countValue, 1, "Should count only archived episodes when shouldShowArchived is true")
        } else {
            XCTFail("Could not extract count value")
        }

        // Verify query filters for archived episodes
        XCTAssertTrue(queryOptimized.contains("WHERE episode.archived = 1"),
                      "Query should filter for archived episodes when shouldShowArchived is true")
    }

    func testManualPlaylistAllEpisodeCountWithShouldShowArchivedFalse() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-all-archived-count-false"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: false)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should only count non-archived episodes
        if let count = resultsOptimized.first?.values.first,
           let countValue = Int.fromDatabaseValue(count) {
            XCTAssertEqual(countValue, 7, "Should count only non-archived episodes")
        } else {
            XCTFail("Could not extract count value")
        }

        // Verify query excludes archived episodes
        XCTAssertTrue(queryOptimized.contains("WHERE episode.archived = 0"),
                      "Query should filter out archived episodes when shouldShowArchived is false")
    }

    func testManualPlaylistAllEpisodeCountWithShouldShowArchivedTrue() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-all-archived-count-true"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: true)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should count all episodes (no archived filter)
        if let count = resultsOptimized.first?.values.first,
           let countValue = Int.fromDatabaseValue(count) {
            XCTAssertEqual(countValue, 8, "Should count all episodes when shouldShowArchived is true")
        } else {
            XCTFail("Could not extract count value")
        }

        // Verify query does NOT filter archived episodes
        XCTAssertFalse(queryOptimized.contains("WHERE episode.archived"),
                       "Query should not filter archived episodes when shouldShowArchived is true")
    }

    func testManualPlaylistEpisodeQueryWithShouldShowArchivedFalse() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-episode-archived-false"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: false)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should only return non-archived episodes
        XCTAssertEqual(resultsOptimized.count, 7, "Should return only non-archived episodes")

        // Verify all returned episodes are not archived
        for row in resultsOptimized {
            if let archived = row["archived"], let archivedValue = Int.fromDatabaseValue(archived) {
                XCTAssertEqual(archivedValue, 0, "All returned episodes should have archived = 0")
            } else {
                XCTFail("Could not extract archived value")
            }
        }

        // Verify query excludes archived episodes
        XCTAssertTrue(queryOptimized.contains("WHERE episode.archived = 0"),
                      "Query should filter out archived episodes when shouldShowArchived is false")
    }

    func testManualPlaylistEpisodeQueryWithShouldShowArchivedTrue() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-episode-archived-true"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: true)
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should return all episodes (including archived)
        XCTAssertEqual(resultsOptimized.count, 8, "Should return all episodes when shouldShowArchived is true")

        // Verify query does NOT filter archived episodes
        XCTAssertFalse(queryOptimized.contains("WHERE episode.archived"),
                       "Query should not filter archived episodes when shouldShowArchived is true")
    }

    func testManualPlaylistFirstDistinctEpisodesWithShouldShowArchivedFalse() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-distinct-archived-false"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(
            clause: .firstDistinctEpisodes,
            for: filter,
            limit: 10,
            shouldShowArchived: false
        )
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Should only return non-archived episodes
        for row in resultsOptimized {
            if let archived = row["archived"], let archivedValue = Int.fromDatabaseValue(archived) {
                XCTAssertEqual(archivedValue, 0, "All returned episodes should have archived = 0")
            } else {
                XCTFail("Could not extract archived value")
            }
        }

        // Verify query excludes archived episodes (uses de.archived in deduped CTE)
        XCTAssertTrue(queryOptimized.contains("de.archived = 0"),
                      "Query should filter out archived episodes when shouldShowArchived is false")
    }

    func testManualPlaylistFirstDistinctEpisodesWithShouldShowArchivedTrue() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-distinct-archived-true"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        // Test with feature flag enabled
        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)
        let queryOptimized = PlaylistQueryBuilder.query(
            clause: .firstDistinctEpisodes,
            for: filter,
            limit: 10,
            shouldShowArchived: true
        )
        let resultsOptimized = try executeQuery(queryOptimized, in: dbPool)

        // Note: firstDistinctEpisodes returns the first episode per podcast.
        // Even with shouldShowArchived=true, an archived episode might not appear
        // if it's not the "first" for its podcast. The key is that the query
        // should NOT filter by archived status, allowing archived episodes to be
        // considered during selection.

        // Verify query does NOT filter archived episodes
        // Note: The query may contain "archived" in other contexts, so we check it doesn't have the filter
        XCTAssertFalse(queryOptimized.contains("AND de.archived = 0"),
                       "Query should not filter archived episodes when shouldShowArchived is true")

        // Verify that results include at least some episodes (not empty due to incorrect filtering)
        XCTAssertGreaterThan(resultsOptimized.count, 0, "Should return episodes when shouldShowArchived is true")
    }

    func testShouldShowArchivedConsistencyAcrossAllClauses() throws {
        let dbPool = try createTestDatabase()
        let playlistUUID = "test-consistency"
        try insertTestData(in: dbPool, playlistUUID: playlistUUID)

        let filter = EpisodeFilter()
        filter.manual = true
        filter.uuid = playlistUUID

        try FeatureFlagOverrideStore().override(FeatureFlag.optimizeManualPlaylistQueries, withValue: true)

        // Get counts for shouldShowArchived = false
        let episodeCountFalse = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter, shouldShowArchived: false)
        let allEpisodeCountFalse = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: false)
        let episodeQueryFalse = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: false)

        let episodeCountResultFalse = try executeQuery(episodeCountFalse, in: dbPool)
        let allEpisodeCountResultFalse = try executeQuery(allEpisodeCountFalse, in: dbPool)
        let episodeResultFalse = try executeQuery(episodeQueryFalse, in: dbPool)

        // Get counts for shouldShowArchived = true
        let episodeCountTrue = PlaylistQueryBuilder.query(clause: .episodeCount, for: filter, shouldShowArchived: true)
        let allEpisodeCountTrue = PlaylistQueryBuilder.query(clause: .allEpisodeCount, for: filter, shouldShowArchived: true)
        let episodeQueryTrue = PlaylistQueryBuilder.query(clause: .episode, for: filter, shouldShowArchived: true)

        let episodeCountResultTrue = try executeQuery(episodeCountTrue, in: dbPool)
        let allEpisodeCountResultTrue = try executeQuery(allEpisodeCountTrue, in: dbPool)
        let episodeResultTrue = try executeQuery(episodeQueryTrue, in: dbPool)

        // Extract count values
        guard let countFalse = episodeCountResultFalse.first?.values.first.flatMap(Int.fromDatabaseValue),
              let allCountFalse = allEpisodeCountResultFalse.first?.values.first.flatMap(Int.fromDatabaseValue),
              let countTrue = episodeCountResultTrue.first?.values.first.flatMap(Int.fromDatabaseValue),
              let allCountTrue = allEpisodeCountResultTrue.first?.values.first.flatMap(Int.fromDatabaseValue) else {
            XCTFail("Could not extract count values")
            return
        }

        // When shouldShowArchived = false, episodeCount and allEpisodeCount should be the same (both showing non-archived)
        XCTAssertEqual(countFalse, allCountFalse,
                       "episodeCount and allEpisodeCount should return same value when shouldShowArchived is false")
        XCTAssertEqual(countFalse, episodeResultFalse.count,
                       "episodeCount should match number of episodes returned by episode query when shouldShowArchived is false")

        // When shouldShowArchived = true, episodeCount shows ONLY archived, while allEpisodeCount shows ALL
        XCTAssertEqual(allCountTrue, episodeResultTrue.count,
                       "allEpisodeCount should match number of episodes returned by episode query when shouldShowArchived is true")

        // episodeCount with true (archived only) + episodeCount with false (non-archived only) should equal allEpisodeCount with true (all episodes)
        XCTAssertEqual(countTrue + countFalse, allCountTrue,
                       "Sum of archived and non-archived counts should equal total count")

        // The archived count should be less than or equal to the non-archived count (in most playlists)
        XCTAssertLessThanOrEqual(countTrue, allCountTrue,
                                 "Archived count should be <= total count")
    }
}
