@testable import PocketCastsServer
import PocketCastsDataModel
import FMDB
import XCTest
@testable import PocketCastsUtils

final class SyncTaskTests_EpisodeImport: XCTestCase {
    private var dataManager: DataManager!
    private var syncTask: SyncTask!

    override func setUp() {
        dataManager = DataManager(dbQueue: FMDatabaseQueue(), shouldCloseQueueAfterSetup: false)
        syncTask = SyncTask(dataManager: dataManager)
        FeatureFlagMock().set(.useSyncResponseEpisodeIDs, value: true)
    }

    override func tearDown() {
        FeatureFlagMock().reset()
    }

    func testSyncingEpisodes() throws {
        let beforeUnsynced = DataManager.sharedManager.unsyncedEpisodes(limit: ServerConstants.Limits.maxEpisodesToSync)
        XCTAssertEqual(beforeUnsynced.count, 0)

        let episodeCount = 5

        (0..<episodeCount).forEach { _ in
            let episode = addEpisode()
            episode.playingStatusModified = 1
            DataManager.sharedManager.save(episode: episode)
        }

        let afterUnsynced = DataManager.sharedManager.unsyncedEpisodes(limit: ServerConstants.Limits.maxEpisodesToSync)
        XCTAssertEqual(afterUnsynced.count, episodeCount)

        let response = Api_SyncUpdateResponse.episodesResponse(episodes: afterUnsynced)
        syncTask.processServerData(response: response)

        let unsyncedEpisodes = DataManager.sharedManager.unsyncedEpisodes(limit: ServerConstants.Limits.maxEpisodesToSync)

        XCTAssertEqual(unsyncedEpisodes.count, 0)
    }
}

private extension SyncTaskTests_EpisodeImport {
    @discardableResult
    func addEpisode(episodeUuid: String = "episode-\(UUID().uuidString)",
                     podcastUuid: String = "podcast-\(UUID().uuidString)") -> Episode {
        let episode = Episode()
        episode.addedDate = Date()
        episode.podcast_id = 0
        episode.podcastUuid = podcastUuid
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        episode.uuid = episodeUuid

        DataManager.sharedManager.save(episode: episode)
        return episode
    }
}

private extension Api_SyncUpdateResponse {
    static func episodesResponse(episodes: [Episode]) -> Self {
        var response = Api_SyncUpdateResponse()

        for episode in episodes {
            let episode = Api_SyncUserEpisode(uuid: episode.uuid,
                                              podcast: episode.podcastUuid)

            var record = Api_Record()
            record.record = .episode(episode)
            record.episode = episode

            response.records.append(record)
        }

        return response
    }
}

private extension Api_SyncUserEpisode {
    static func fromBookmark(_ episode: Episode) -> Self {
        return .init(uuid: episode.uuid,
                     podcast: episode.podcastUuid)
    }

    init(uuid: String,
         podcast: String) {
        self.init()

        self.uuid = uuid
        self.podcastUuid = podcast
    }
}
