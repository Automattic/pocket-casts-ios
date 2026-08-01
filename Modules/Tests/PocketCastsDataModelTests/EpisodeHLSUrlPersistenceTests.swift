import XCTest
@testable import PocketCastsDataModel

/// Verifies that an episode's `hlsUrl` survives a save → load round-trip. This is the storage that
/// every server → DB path (feed refresh, Up Next sync, episode update) writes the HLS url into.
final class EpisodeHLSUrlPersistenceTests: DataManagerTestCase {

    func testHlsUrlPersistsThroughSaveAndLoad() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            episode.hlsUrl = "https://example.com/stream.m3u8"
            dataManager.save(episode: episode)

            let loaded = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(loaded?.hlsUrl, "https://example.com/stream.m3u8", "\(implementationName) should persist hlsUrl")
        }
    }

    func testHlsUrlCanBeUpdatedOnAnExistingEpisode() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            episode.hlsUrl = "https://example.com/old.m3u8"
            dataManager.save(episode: episode)

            episode.hlsUrl = "https://example.com/new.m3u8"
            dataManager.save(episode: episode)

            let loaded = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertEqual(loaded?.hlsUrl, "https://example.com/new.m3u8", "\(implementationName) should update hlsUrl")
        }
    }

    func testHlsUrlIsNilByDefault() throws {
        try runWithBothImplementations { dataManager, implementationName in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(podcast: podcast, dataManager: dataManager)

            let loaded = dataManager.findEpisode(uuid: episode.uuid)
            XCTAssertNil(loaded?.hlsUrl, "\(implementationName) should leave hlsUrl nil when unset")
        }
    }
}
