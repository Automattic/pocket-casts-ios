import XCTest
import GRDB
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

/// Base test class for DataManager tests that automatically runs tests with both
/// GRDB API and raw SQL implementations
///
/// Subclasses should:
/// 1. Override `setUpWithDataManager(_:)` to set up test data
/// 2. Override `tearDownWithDataManager(_:)` if additional cleanup is needed
/// 3. Call `runWithBothImplementations { ... }` in test methods to run assertions
///    against both implementations
///
/// Example:
/// ```
/// final class EpisodeDataManagerTests: DataManagerTestCase {
///     func testFindEpisodeByUuid() async throws {
///         try await runWithBothImplementations { dataManager, implementationName in
///             let podcast = self.createTestPodcast(dataManager: dataManager)
///             let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)
///             let found = dataManager.findEpisode(uuid: episode.uuid)
///             XCTAssertNotNil(found, "\(implementationName) should find episode")
///         }
///     }
/// }
/// ```
class DataManagerTestCase: XCTestCase {
    private var featureFlagStore: FeatureFlagOverrideStore!

    override func setUp() async throws {
        try await super.setUp()
        featureFlagStore = FeatureFlagOverrideStore()
    }

    override func tearDown() async throws {
        // Reset the feature flag override
        featureFlagStore.resetOverrides()
        featureFlagStore = nil
        try await super.tearDown()
    }

    /// Runs the provided test block with both SQL and GRDB API implementations.
    ///
    /// - Parameter testBlock: A closure that receives a DataManager and the implementation name.
    ///                        The implementation name is either "SQL" or "GRDB".
    func runWithBothImplementations(_ testBlock: (DataManager, String) throws -> Void) throws {
        // Test with raw SQL query
        let sqlDataManager = DataManager.newTestDataManager()
        try testBlock(sqlDataManager, "SQL")

        // Test with GRDB implementation
        try featureFlagStore.override(FeatureFlag.grdbQueryInterface, withValue: true)
        let grdbDataManager = DataManager.newTestDataManager()
        try testBlock(grdbDataManager, "GRDB")
        featureFlagStore.resetOverrides()
    }

    /// Async version of runWithBothImplementations
    func runWithBothImplementations(_ testBlock: (DataManager, String) async throws -> Void) async throws {
        // Test with SQL implementation
        let sqlDataManager = DataManager.newTestDataManager()
        try await testBlock(sqlDataManager, "SQL")

        // Test with GRDB implementation
        try featureFlagStore.override(FeatureFlag.grdbQueryInterface, withValue: true)
        let grdbDataManager = DataManager.newTestDataManager()
        try await testBlock(grdbDataManager, "GRDB")
        featureFlagStore.resetOverrides()
    }

    // MARK: - Common Test Helpers

    /// Creates a test podcast with the given properties
    func createTestPodcast(
        uuid: String = UUID().uuidString,
        title: String = "Test Podcast",
        subscribed: Int32 = 1,
        sortOrder: Int32 = 0,
        folderUuid: String? = nil,
        dataManager: DataManager
    ) -> Podcast {
        let podcast = Podcast()
        podcast.uuid = uuid
        podcast.title = title
        podcast.subscribed = subscribed
        podcast.sortOrder = sortOrder
        podcast.folderUuid = folderUuid
        podcast.addedDate = Date()
        dataManager.save(podcast: podcast)
        return podcast
    }

    /// Creates a test episode with the given properties
    @discardableResult
    func createTestEpisode(
        uuid: String = UUID().uuidString,
        podcast: Podcast,
        title: String = "Test Episode",
        publishedDate: Date? = Date(),
        episodeStatus: Int32 = 0,
        playingStatus: Int32 = 0,
        playedUpTo: Double = 0,
        archived: Bool = false,
        wasDeleted: Bool = false,
        lastPlaybackInteractionDate: Date? = nil,
        downloadTaskId: String? = nil,
        dataManager: DataManager
    ) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.title = title
        episode.publishedDate = publishedDate
        episode.addedDate = Date()
        episode.episodeStatus = episodeStatus
        episode.playingStatus = playingStatus
        episode.playedUpTo = playedUpTo
        episode.archived = archived
        episode.wasDeleted = wasDeleted
        episode.lastPlaybackInteractionDate = lastPlaybackInteractionDate
        episode.downloadTaskId = downloadTaskId
        dataManager.save(episode: episode)
        return episode
    }

    /// Creates a test playlist with the given properties
    func createTestPlaylist(
        uuid: String = UUID().uuidString,
        name: String = "Test Playlist",
        manual: Bool = false,
        sortPosition: Int32 = 0,
        syncStatus: Int32 = SyncStatus.notSynced.rawValue,
        wasDeleted: Bool = false,
        dataManager: DataManager
    ) -> EpisodeFilter {
        let playlist = EpisodeFilter()
        playlist.uuid = uuid
        playlist.playlistName = name
        playlist.manual = manual
        playlist.sortPosition = sortPosition
        playlist.syncStatus = syncStatus
        playlist.wasDeleted = wasDeleted
        dataManager.save(playlist: playlist)
        return playlist
    }

    /// Creates a test user episode with the given properties
    func createTestUserEpisode(
        uuid: String = UUID().uuidString,
        title: String = "Test User Episode",
        episodeStatus: Int32 = DownloadStatus.notDownloaded.rawValue,
        uploadStatus: Int32 = UploadStatus.notUploaded.rawValue,
        addedDate: Date = Date(),
        duration: Double = 3600,
        dataManager: DataManager
    ) -> UserEpisode {
        let episode = UserEpisode()
        episode.uuid = uuid
        episode.title = title
        episode.episodeStatus = episodeStatus
        episode.uploadStatus = uploadStatus
        episode.addedDate = addedDate
        episode.duration = duration
        dataManager.save(episode: episode)
        return episode
    }

    /// Creates a test folder with the given properties
    func createTestFolder(
        uuid: String = UUID().uuidString,
        name: String = "Test Folder",
        color: Int32 = 0,
        sortOrder: Int32 = 0,
        dataManager: DataManager
    ) -> Folder {
        let folder = Folder()
        folder.uuid = uuid
        folder.name = name
        folder.color = color
        folder.sortOrder = sortOrder
        folder.addedDate = Date()
        dataManager.save(folder: folder)
        return folder
    }

    /// Adds an episode to the Up Next playlist at the bottom
    func addToUpNextBottom(
        episodeUuid: String,
        title: String = "Test Episode",
        podcastUuid: String = "",
        dataManager: DataManager
    ) {
        let playlistEpisode = PlaylistEpisode()
        playlistEpisode.episodeUuid = episodeUuid
        playlistEpisode.title = title
        playlistEpisode.podcastUuid = podcastUuid
        playlistEpisode.episodePosition = dataManager.positionForPlaylistEpisode(bottomOfList: true)
        dataManager.save(playlistEpisode: playlistEpisode)
    }

    /// Adds an episode to the Up Next playlist at the top
    func addToUpNextTop(
        episodeUuid: String,
        title: String = "Test Episode",
        podcastUuid: String = "",
        dataManager: DataManager
    ) {
        let playlistEpisode = PlaylistEpisode()
        playlistEpisode.episodeUuid = episodeUuid
        playlistEpisode.title = title
        playlistEpisode.podcastUuid = podcastUuid
        playlistEpisode.episodePosition = dataManager.positionForPlaylistEpisode(bottomOfList: false)
        dataManager.save(playlistEpisode: playlistEpisode)
    }
}
