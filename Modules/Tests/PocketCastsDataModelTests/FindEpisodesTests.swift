@testable import PocketCastsDataModel
import XCTest

final class FindEpisodesTests: XCTestCase {
    func testFindEpisodesFiltersByPodcastAndDeletionAndOrdersByDates() {
        let dataManager = DataManager.newTestDataManager()
        let podcastUuid = "pod-filter"

        let newest = makeEpisode(
            uuid: "ep-newest",
            podcastUuid: podcastUuid,
            title: "Latest Daily Breakdown",
            published: 4_000,
            added: 4_000
        )

        let samePublishedNewerAdded = makeEpisode(
            uuid: "ep-same-pub-newer-added",
            podcastUuid: podcastUuid,
            title: "Daily Insights",
            published: 3_000,
            added: 3_500
        )

        let samePublishedOlderAdded = makeEpisode(
            uuid: "ep-same-pub-older-added",
            podcastUuid: podcastUuid,
            title: "Daily Recap",
            published: 3_000,
            added: 3_000
        )

        let otherPodcast = makeEpisode(
            uuid: "ep-other-podcast",
            podcastUuid: "pod-other",
            title: "Daily News Elsewhere",
            published: 5_000,
            added: 5_000,
            podcastId: 2
        )

        let deleted = makeEpisode(
            uuid: "ep-deleted",
            podcastUuid: podcastUuid,
            title: "Daily Deleted",
            published: 2_000,
            added: 2_000
        )
        deleted.wasDeleted = true

        let nonMatching = makeEpisode(
            uuid: "ep-non-matching",
            podcastUuid: podcastUuid,
            title: "Weekly Summary",
            published: 1_000,
            added: 1_000
        )

        [newest,
         samePublishedNewerAdded,
         samePublishedOlderAdded,
         otherPodcast,
         deleted,
         nonMatching].forEach { episode in
            dataManager.save(episode: episode)
        }

        let results = dataManager.findEpisodes(with: "daily", podcastUUID: podcastUuid)
        let resultIds = results.map(\.uuid)

        XCTAssertEqual(resultIds, [
            "ep-newest",
            "ep-same-pub-newer-added",
            "ep-same-pub-older-added"
        ])
    }

    func testFindEpisodesEscapesLikeWildcards() {
        let dataManager = DataManager.newTestDataManager()
        let podcastUuid = "pod-wildcard"

        let percentEpisode = makeEpisode(
            uuid: "ep-percent",
            podcastUuid: podcastUuid,
            title: "Growth up 50% this quarter",
            published: 4_000,
            added: 4_000
        )

        let underscoreEpisode = makeEpisode(
            uuid: "ep-underscore",
            podcastUuid: podcastUuid,
            title: "Release_v2.0 recap",
            published: 3_000,
            added: 3_000
        )

        let plainEpisode = makeEpisode(
            uuid: "ep-plain",
            podcastUuid: podcastUuid,
            title: "Plain title without symbols",
            published: 2_000,
            added: 2_000
        )

        [percentEpisode, underscoreEpisode, plainEpisode].forEach { episode in
            dataManager.save(episode: episode)
        }

        let percentResults = dataManager.findEpisodes(with: "%", podcastUUID: podcastUuid)
        XCTAssertEqual(percentResults.map(\.uuid), ["ep-percent"])

        let underscoreResults = dataManager.findEpisodes(with: "_", podcastUUID: podcastUuid)
        XCTAssertEqual(underscoreResults.map(\.uuid), ["ep-underscore"])
    }

    // MARK: - Helpers

    private func makeEpisode(
        uuid: String,
        podcastUuid: String,
        title: String,
        published: TimeInterval,
        added: TimeInterval,
        podcastId: Int64 = 1
    ) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcastUuid
        episode.podcast_id = podcastId
        episode.title = title
        episode.addedDate = Date(timeIntervalSince1970: added)
        episode.publishedDate = Date(timeIntervalSince1970: published)
        episode.episodeStatus = DownloadStatus.downloaded.rawValue
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        return episode
    }
}
