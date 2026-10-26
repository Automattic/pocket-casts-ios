import XCTest
@testable import PocketCastsDataModel

/// Tests for the episode writes the podcast refresh makes.
final class EpisodeRefreshDataTests: DataManagerTestCase {

    // MARK: - insertEpisodesIfMissing

    func testInsertEpisodesIfMissingSavesOnlyNewEpisodes() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "existing", podcast: podcast, title: "Existing", dataManager: dataManager)

            let inserted = dataManager.insertEpisodesIfMissing([
                self.refreshedEpisode(uuid: "existing", podcast: podcast),
                self.refreshedEpisode(uuid: "new-1", podcast: podcast),
                self.refreshedEpisode(uuid: "new-2", podcast: podcast)
            ])

            XCTAssertEqual(inserted.map(\.uuid), ["new-1", "new-2"])
            XCTAssertEqual(dataManager.findEpisode(uuid: "existing")?.title, "Existing", "Existing episode should be left as it was")
            XCTAssertEqual(dataManager.findEpisode(uuid: "new-1")?.title, "Server title")
            XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).count, 3)
        }
    }

    func testInsertEpisodesIfMissingSavesAnEpisodeListedTwiceOnce() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)

            let inserted = dataManager.insertEpisodesIfMissing([
                self.refreshedEpisode(uuid: "duplicate", podcast: podcast),
                self.refreshedEpisode(uuid: "duplicate", podcast: podcast)
            ])

            XCTAssertEqual(inserted.count, 1)
            XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).count, 1)
        }
    }

    func testInsertEpisodesIfMissingHandlesMoreEpisodesThanOneLookup() throws {
        try runWithDataManager { dataManager in
            let podcast = self.createTestPodcast(dataManager: dataManager)
            _ = self.createTestEpisode(uuid: "episode-700", podcast: podcast, dataManager: dataManager)

            let inserted = dataManager.insertEpisodesIfMissing((0..<1_200).map { self.refreshedEpisode(uuid: "episode-\($0)", podcast: podcast) })

            XCTAssertEqual(inserted.count, 1_199)
            XCTAssertEqual(dataManager.allEpisodes(forPodcastId: podcast.id).count, 1_200)
        }
    }

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
