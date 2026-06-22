import XCTest
@testable import podcasts
@testable import PocketCastsDataModel
@testable import PocketCastsUtils

final class PlaybackQueueTests: XCTestCase {

    let featureFlagMock = FeatureFlagMock()

    func testOverrideAllEpisodesWith_shouldNotIncludeStaleEpisodesInReplace() {
        FeatureFlagMock().set(.replaceSpecificEpisode, value: true)

        let playbackQueue = PlaybackQueue()
        let mockDataManager = MockDataManager()
        DataManager.sharedManager = mockDataManager

        let staleEpisode = PlaylistEpisode()
        staleEpisode.episodeUuid = "stale-uuid"
        staleEpisode.title = "Stale Episode"
        mockDataManager.upNextEpisodes = [staleEpisode]
        mockDataManager.delayCacheClearUntilManuallyCalled()

        let newEpisode = UserEpisode()
        newEpisode.uuid = "current-uuid"
        newEpisode.title = "Current Episode"

        playbackQueue.overrideAllEpisodesWith(episode: newEpisode)

        // Simulate delayed clearing of the cache
        mockDataManager.manuallyClearCache()

        // The replacement list should only contain the current episode (added later), not the stale one
        XCTAssertFalse(mockDataManager.savedReplaceEpisodes.contains("stale-uuid"),
                       "Should not include stale episode UUID in replacement list")
    }

    func testReorderUpNextPersistsNewOrderAndKeepsMissingEntriesAtBottom() {
        let playbackQueue = PlaybackQueue()
        let mockDataManager = MockDataManager()
        DataManager.sharedManager = mockDataManager

        // Position 0 is the now playing episode, which stays pinned and isn't reordered.
        mockDataManager.upNextEpisodes = [
            playlistEpisode(uuid: "now-playing", position: 0),
            playlistEpisode(uuid: "a", position: 1),
            playlistEpisode(uuid: "b", position: 2),
            playlistEpisode(uuid: "missing", position: 3) // no matching episode in sortedEpisodes
        ]

        // Desired new order for the known episodes.
        playbackQueue.reorderUpNext(sortedEpisodes: [episode("b"), episode("a")])

        let savedUuids = mockDataManager.savedPlaylistEpisodes.map { $0.episodeUuid }
        let savedPositions = mockDataManager.savedPlaylistEpisodes.map { $0.episodePosition }

        // The known episodes follow the sorted order, the missing entry sinks to the bottom...
        XCTAssertEqual(savedUuids, ["b", "a", "missing"])
        // ...and positions start at 1 since position 0 is reserved for the now playing episode.
        XCTAssertEqual(savedPositions, [1, 2, 3])
    }

    func testReorderUpNextDoesNothingWithFewerThanTwoSortedEpisodes() {
        let playbackQueue = PlaybackQueue()
        let mockDataManager = MockDataManager()
        DataManager.sharedManager = mockDataManager

        mockDataManager.upNextEpisodes = [
            playlistEpisode(uuid: "now-playing", position: 0),
            playlistEpisode(uuid: "a", position: 1)
        ]

        playbackQueue.reorderUpNext(sortedEpisodes: [episode("a")])

        XCTAssertTrue(mockDataManager.savedPlaylistEpisodes.isEmpty, "Reordering one episode should be a no-op")
    }

    private func playlistEpisode(uuid: String, position: Int32) -> PlaylistEpisode {
        let playlistEpisode = PlaylistEpisode()
        playlistEpisode.episodeUuid = uuid
        playlistEpisode.episodePosition = position
        return playlistEpisode
    }

    private func episode(_ uuid: String) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        return episode
    }

    func testRecentUserInteractionReturnsFalseWhenNoPreviousInteraction() {
        let playbackQueue = PlaybackQueue()

        XCTAssertFalse(playbackQueue.recentUserInteraction(now: Date(timeIntervalSince1970: 15)))
    }

    func testRecentUserInteractionReturnsTrueWithinGracePeriod() {
        let playbackQueue = PlaybackQueue()
        let interactionTime = Date(timeIntervalSince1970: 1_000)
        playbackQueue.recordUpNextUserInteraction(at: interactionTime)

        XCTAssertTrue(playbackQueue.recentUserInteraction(now: interactionTime.addingTimeInterval(3)))
    }

    func testRecentUserInteractionReturnsFalseAtGracePeriodBoundary() {
        let playbackQueue = PlaybackQueue()
        let interactionTime = Date(timeIntervalSince1970: 1_000)
        playbackQueue.recordUpNextUserInteraction(at: interactionTime)

        XCTAssertFalse(playbackQueue.recentUserInteraction(now: interactionTime.addingTimeInterval(10)))
    }

    func testRecentUserInteractionReturnsFalseOutsideGracePeriod() {
        let playbackQueue = PlaybackQueue()
        let interactionTime = Date(timeIntervalSince1970: 1_000)
        playbackQueue.recordUpNextUserInteraction(at: interactionTime)

        XCTAssertFalse(playbackQueue.recentUserInteraction(now: interactionTime.addingTimeInterval(11)))
    }

    override func tearDown() {
        featureFlagMock.reset()
    }
}

fileprivate class MockDataManager: DataManager {
    var savedReplaceEpisodes: [String] = []
    var savedPlaylistEpisodes: [PlaylistEpisode] = []
    var upNextEpisodes: [PlaylistEpisode] = []
    var deleteCalled = false
    var cacheManuallyDelayed = false

    override func allUpNextPlaylistEpisodes() -> [PlaylistEpisode] {
        return upNextEpisodes
    }

    override func save(playlistEpisodes: [PlaylistEpisode]) {
        savedPlaylistEpisodes = playlistEpisodes
    }

    override func deleteAllUpNextEpisodes() {
        deleteCalled = true
        if !cacheManuallyDelayed {
            upNextEpisodes.removeAll()
        }
    }

    override func saveReplace(episodeList: [String]) {
        savedReplaceEpisodes = episodeList
    }

    // Allows simulating delay in cache clearing
    func delayCacheClearUntilManuallyCalled() {
        cacheManuallyDelayed = true
    }

    func manuallyClearCache() {
        upNextEpisodes.removeAll()
    }
}
