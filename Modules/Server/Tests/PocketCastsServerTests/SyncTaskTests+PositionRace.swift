@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import SwiftProtobuf
import XCTest

/// Tests demonstrating that SyncTask.importEpisode unconditionally overwrites
/// the local playedUpTo with the server value, without any recency check.
///
/// The core issue in SyncTask+ServerChanges.swift:229-238:
///   1. The DB write (line 231) is unconditional — no timestamp comparison
///   2. The seek (line 238) fires for every write where the value differs
///   3. The `playedUpToModified` field exists in the protobuf but is never checked
///
/// This means any sync response — including one carrying a stale position — will
/// overwrite the local DB and seek the player to that stale position.
final class SyncTaskTests_PositionRace: XCTestCase {
    private var syncTask: SyncTask!
    private var mockPlaybackDelegate: MockPlaybackDelegate!
    private var originalPlaybackDelegate: ServerPlaybackDelegate?

    override func setUp() {
        super.setUp()
        syncTask = SyncTask(dataManager: DataManager.sharedManager)
        mockPlaybackDelegate = MockPlaybackDelegate()
        originalPlaybackDelegate = ServerConfig.shared.playbackDelegate
        ServerConfig.shared.playbackDelegate = mockPlaybackDelegate
    }

    override func tearDown() {
        ServerConfig.shared.playbackDelegate = originalPlaybackDelegate
        FeatureFlagMock().reset()
        super.tearDown()
    }

    // MARK: - Tests

    /// A sync response with a lower playedUpTo than the current DB value
    /// overwrites the DB and seeks the player backward.
    func testSyncResponseOverwritesNewerLocalPosition() {
        let episode = createEpisodeInDB(playedUpTo: 146)
        mockPlaybackDelegate.nowPlayingUuid = episode.uuid
        mockPlaybackDelegate.isPlaying = false

        // Server sends a stale position (132) that is older than local (146)
        let staleResponse = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 132
        )
        syncTask.processServerData(response: staleResponse)

        // The DB is overwritten with the stale value
        let savedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid)
        XCTAssertEqual(Int64(savedEpisode?.playedUpTo ?? 0), 132,
                       "DB position is overwritten by stale sync value — no recency check")

        // The player is seeked backward
        XCTAssertEqual(mockPlaybackDelegate.seekHistory.count, 1)
        XCTAssertEqual(mockPlaybackDelegate.seekHistory[0].time, 132,
                       "Player seeks backward to the stale position")
    }

    /// Two consecutive processServerData calls with different positions both
    /// write to the DB and seek, with the last one winning regardless of recency.
    func testConsecutiveSyncResponsesLastWriteWins() {
        let episode = createEpisodeInDB(playedUpTo: 100)
        mockPlaybackDelegate.nowPlayingUuid = episode.uuid
        mockPlaybackDelegate.isPlaying = false

        // First response: position 146
        let response1 = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 146
        )
        syncTask.processServerData(response: response1)

        // Second response: position 132 (stale)
        let response2 = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 132
        )
        syncTask.processServerData(response: response2)

        // Both seeks fire — the second one moves backward
        XCTAssertEqual(mockPlaybackDelegate.seekHistory.count, 2)
        XCTAssertEqual(mockPlaybackDelegate.seekHistory[0].time, 146)
        XCTAssertEqual(mockPlaybackDelegate.seekHistory[1].time, 132,
                       "Second seek moves backward — last write wins")

        // DB has the stale value
        let savedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid)
        XCTAssertEqual(Int64(savedEpisode?.playedUpTo ?? 0), 132)
    }

    /// The playedUpToModified timestamp field exists in the protobuf but
    /// importEpisode does not use it for comparison. This test documents that
    /// even when the server sends a modified timestamp, it is ignored.
    ///
    /// Compare with how `deselectedChapters` uses `saveIfNotModified(chapters:remoteModified:)`
    /// at SyncTask+ServerChanges.swift:187 — that field IS guarded by its timestamp.
    func testPlayedUpToModifiedTimestampIsIgnored() {
        let episode = createEpisodeInDB(playedUpTo: 100)
        mockPlaybackDelegate.nowPlayingUuid = episode.uuid
        mockPlaybackDelegate.isPlaying = false

        // Response with an older timestamp but the position still overwrites
        let response = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 50,
            playedUpToModified: 1000  // old timestamp
        )
        syncTask.processServerData(response: response)

        // The stale position is applied despite having an older timestamp
        let savedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid)
        XCTAssertEqual(Int64(savedEpisode?.playedUpTo ?? 0), 50,
                       "playedUpToModified is not checked — stale position applied")
        XCTAssertEqual(mockPlaybackDelegate.seekHistory.count, 1,
                       "Seek fires regardless of timestamp")
    }

    /// Documents that a remote response with playedUpToModified=0 (or missing)
    /// still overwrites the local position, even if the local episode has a
    /// non-zero playedUpToModified from recent local playback.
    ///
    /// A correct fix using saveIfNotModified(playedUpTo:remoteModified:) would
    /// reject this update because `WHERE playedUpToModified < 0` matches no rows.
    func testRemoteWithZeroTimestampOverwritesLocalProgress() {
        let episode = createEpisodeInDB(playedUpTo: 500)
        // Simulate local playback having set a modified timestamp
        episode.playedUpToModified = 1773247000000
        DataManager.sharedManager.save(episode: episode)

        mockPlaybackDelegate.nowPlayingUuid = episode.uuid
        mockPlaybackDelegate.isPlaying = false

        // Server sends playedUpTo=50 with no modified timestamp (defaults to 0)
        let response = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 50
        )
        syncTask.processServerData(response: response)

        // Current behavior: overwrites despite missing recency signal
        let savedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid)
        XCTAssertEqual(Int64(savedEpisode?.playedUpTo ?? 0), 50,
                       "Position overwritten even without remote timestamp — no recency check")
    }

    /// The DB write at SyncTask+ServerChanges.swift:231 happens unconditionally,
    /// even when the player is actively playing. Only the seek is guarded.
    func testDBWriteHappensEvenWhilePlaying() {
        let episode = createEpisodeInDB(playedUpTo: 100)
        mockPlaybackDelegate.nowPlayingUuid = episode.uuid
        mockPlaybackDelegate.isPlaying = true

        let response = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 50
        )
        syncTask.processServerData(response: response)

        // Seek is correctly blocked while playing
        XCTAssertTrue(mockPlaybackDelegate.seekHistory.isEmpty,
                      "Should not seek while actively playing")

        // But the DB IS overwritten with the stale value
        let savedEpisode = DataManager.sharedManager.findEpisode(uuid: episode.uuid)
        XCTAssertEqual(Int64(savedEpisode?.playedUpTo ?? 0), 50,
                       "DB is overwritten even while playing — only seek is guarded")
    }

    /// Sync does not seek for episodes that aren't the now-playing episode.
    func testSyncDoesNotSeekForNonPlayingEpisode() {
        let episode = createEpisodeInDB(playedUpTo: 100)
        mockPlaybackDelegate.nowPlayingUuid = "some-other-uuid"
        mockPlaybackDelegate.isPlaying = false

        let response = Api_SyncUpdateResponse.withPlayedUpTo(
            episodeUuid: episode.uuid,
            podcastUuid: episode.podcastUuid,
            playedUpTo: 200
        )
        syncTask.processServerData(response: response)

        XCTAssertTrue(mockPlaybackDelegate.seekHistory.isEmpty,
                      "Should not seek for non-playing episode")
    }

    // MARK: - Helpers

    @discardableResult
    private func createEpisodeInDB(
        episodeUuid: String = "episode-\(UUID().uuidString)",
        podcastUuid: String = "podcast-\(UUID().uuidString)",
        playedUpTo: Double = 0
    ) -> Episode {
        let episode = Episode()
        episode.addedDate = Date()
        episode.podcast_id = 0
        episode.podcastUuid = podcastUuid
        episode.playingStatus = PlayingStatus.inProgress.rawValue
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        episode.uuid = episodeUuid
        episode.playedUpTo = playedUpTo
        episode.duration = 3600

        DataManager.sharedManager.save(episode: episode)
        return episode
    }
}

// MARK: - Mock Playback Delegate

/// Captures all seek calls so tests can verify the sequence and direction of seeks.
private class MockPlaybackDelegate: ServerPlaybackDelegate {
    struct SeekRecord {
        let time: TimeInterval
        let syncChanges: Bool
        let startPlaybackAfterSeek: Bool
    }

    var seekHistory: [SeekRecord] = []
    var nowPlayingUuid: String?
    var isPlaying: Bool = false

    func seekToFromSync(time: TimeInterval, syncChanges: Bool, startPlaybackAfterSeek: Bool) {
        seekHistory.append(SeekRecord(time: time, syncChanges: syncChanges, startPlaybackAfterSeek: startPlaybackAfterSeek))
    }

    func playing() -> Bool { isPlaying }
    func isNowPlayingEpisode(episodeUuid: String?) -> Bool { episodeUuid == nowPlayingUuid }
    func isActivelyPlaying(episodeUuid: String?) -> Bool { isPlaying && episodeUuid == nowPlayingUuid }
    func currentEpisode() -> BaseEpisode? { nil }
    func inUpNext(episode: BaseEpisode?) -> Bool { false }
    func addToUpNext(episode: BaseEpisode, ignoringQueueLimit: Bool, toTop: Bool) {}
    func removeLastEpisodeFromUpNext() {}
    func queuePersistLocalCopyAsReplace() {}
    func queueRefreshList(checkForAutoDownload: Bool) {}
    func allEpisodesInQueue(includeNowPlaying: Bool) -> [BaseEpisode] { [] }
    func playingEpisodeChangedExternally() {}
    func upNextQueueChanged() {}
    func upNextQueueCount() -> Int { 0 }
}

// MARK: - Protobuf Helpers

private extension Api_SyncUpdateResponse {
    /// Creates a sync response containing a single episode with a specific playedUpTo value.
    static func withPlayedUpTo(
        episodeUuid: String,
        podcastUuid: String,
        playedUpTo: Int64,
        playedUpToModified: Int64? = nil
    ) -> Self {
        var episodeItem = Api_SyncUserEpisode()
        episodeItem.uuid = episodeUuid
        episodeItem.podcastUuid = podcastUuid
        episodeItem.playedUpTo = Google_Protobuf_Int64Value(playedUpTo)

        if let modified = playedUpToModified {
            episodeItem.playedUpToModified = Google_Protobuf_Int64Value(modified)
        }

        var record = Api_Record()
        record.record = .episode(episodeItem)
        record.episode = episodeItem

        var response = Api_SyncUpdateResponse()
        response.records.append(record)
        return response
    }
}
