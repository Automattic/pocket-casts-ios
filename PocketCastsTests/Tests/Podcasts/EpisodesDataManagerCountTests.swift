import XCTest
import PocketCastsDataModel
@testable import podcasts

final class EpisodesDataManagerCountTests: DBTestCase {
    private let episodesDataManager = EpisodesDataManager()
    private var episodes: [Episode] = []

    override func setUp() async throws {
        try await super.setUp()

        episodes = (0..<4).map { index in
            let episode = Episode()
            episode.uuid = UUID().uuidString
            episode.podcastUuid = podcast.uuid
            episode.podcast_id = podcast.id
            episode.addedDate = Date()
            episode.archived = index < 2
            dataManager.save(episode: episode)
            return episode
        }
    }

    func testCountsWithoutFilterIncludeAllEpisodes() {
        XCTAssertEqual(episodesDataManager.episodeCount(for: podcast), 5)
        XCTAssertEqual(episodesDataManager.archivedEpisodeCount(for: podcast), 2)
    }

    func testCountsWithFilterOnlyIncludeMatchingEpisodes() {
        let uuids = [episodes[0].uuid, episodes[2].uuid]

        XCTAssertEqual(episodesDataManager.episodeCount(for: podcast, uuidsToFilter: uuids), 2)
        XCTAssertEqual(episodesDataManager.archivedEpisodeCount(for: podcast, uuidsToFilter: uuids), 1)
    }

    func testCountsWithEmptyFilterAreZero() {
        XCTAssertEqual(episodesDataManager.episodeCount(for: podcast, uuidsToFilter: []), 0)
        XCTAssertEqual(episodesDataManager.archivedEpisodeCount(for: podcast, uuidsToFilter: []), 0)
    }

    func testCountsWithFilterIgnoreEpisodesOfOtherPodcasts() {
        let other = Episode()
        other.uuid = UUID().uuidString
        other.podcastUuid = UUID().uuidString
        other.podcast_id = podcast.id + 100
        other.addedDate = Date()
        dataManager.save(episode: other)

        XCTAssertEqual(episodesDataManager.episodeCount(for: podcast, uuidsToFilter: [other.uuid]), 0)
    }
}
