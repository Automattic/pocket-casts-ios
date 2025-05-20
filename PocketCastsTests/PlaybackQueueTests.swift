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

    override func tearDown() {
        featureFlagMock.reset()
    }
}

fileprivate class MockDataManager: DataManager {
    var savedReplaceEpisodes: [String] = []
    var upNextEpisodes: [PlaylistEpisode] = []
    var deleteCalled = false
    var cacheManuallyDelayed = false

    override func allUpNextPlaylistEpisodes() -> [PlaylistEpisode] {
        return upNextEpisodes
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
