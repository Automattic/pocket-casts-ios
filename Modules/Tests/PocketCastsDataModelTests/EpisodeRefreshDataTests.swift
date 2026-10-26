import XCTest
@testable import PocketCastsDataModel

/// Tests for the episode writes the podcast refresh makes.
final class EpisodeRefreshDataTests: DataManagerTestCase {

    // MARK: - fillMissingDetails

    func testFillMissingDetailsUpdatesEpisodeSavedWithoutDetails() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let placeholder = self.createTestEpisode(uuid: "placeholder", podcast: podcast, title: "From Up Next", dataManager: dataManager)

            dataManager.fillMissingDetails(from: [self.refreshedEpisode(uuid: placeholder.uuid, podcast: podcast)])

            let found = try XCTUnwrap(dataManager.findEpisode(uuid: "placeholder"))
            XCTAssertEqual(found.fileType, "audio/mp3")
            XCTAssertEqual(found.detailedDescription, "Show notes")
            XCTAssertEqual(found.sizeInBytes, 1_000)
            XCTAssertEqual(found.duration, 600)
            XCTAssertEqual(found.episodeNumber, 7)
            XCTAssertEqual(found.title, "From Up Next", "Title saved from Up Next should stay")
        }
    }

    func testFillMissingDetailsKeepsDurationAlreadySet() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let placeholder = self.createTestEpisode(uuid: "placeholder", podcast: podcast, dataManager: dataManager)
            dataManager.saveEpisode(duration: 1_234, episode: placeholder, updateSyncFlag: false)

            dataManager.fillMissingDetails(from: [self.refreshedEpisode(uuid: placeholder.uuid, podcast: podcast)])

            XCTAssertEqual(dataManager.findEpisode(uuid: "placeholder")?.duration, 1_234)
        }
    }

    func testFillMissingDetailsLeavesEpisodesThatHaveDetails() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            let episode = self.createTestEpisode(uuid: "complete", podcast: podcast, dataManager: dataManager)
            episode.fileType = "video/mp4"
            episode.detailedDescription = "Original notes"
            dataManager.save(episode: episode)

            dataManager.fillMissingDetails(from: [self.refreshedEpisode(uuid: episode.uuid, podcast: podcast)])

            let found = try XCTUnwrap(dataManager.findEpisode(uuid: "complete"))
            XCTAssertEqual(found.fileType, "video/mp4")
            XCTAssertEqual(found.detailedDescription, "Original notes")
        }
    }

    // MARK: - Helpers

    private func refreshedEpisode(uuid: String, podcast: Podcast) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcast.uuid
        episode.podcast_id = podcast.id
        episode.title = "Server title"
        episode.fileType = "audio/mp3"
        episode.episodeDescription = "Description"
        episode.detailedDescription = "Show notes"
        episode.sizeInBytes = 1_000
        episode.duration = 600
        episode.episodeType = "full"
        episode.seasonNumber = 2
        episode.episodeNumber = 7
        return episode
    }
}
