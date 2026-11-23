import XCTest
@testable import PocketCastsDataModel

final class PlaybackStatsDataManagerTests: DataManagerTestCase {
    private let year = 2026

    private func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string)!
    }

    func testPodcastStatsCountsADuplicatedPodcastOnce() throws {
        try runWithDataManager { dataManager in
            let uuid = "f61425f0-8803-0133-2d8b-6dc413d6d41d"
            let firstRow = self.createTestPodcast(uuid: uuid, title: "Optimal Living Daily", subscribed: 0, dataManager: dataManager)
            let secondRow = self.createTestPodcast(uuid: uuid, title: "Optimal Living Daily", subscribed: 0, dataManager: dataManager)
            XCTAssertNotEqual(firstRow.id, secondRow.id)
            self.createTestEpisode(podcast: firstRow, playedUpTo: 546, lastPlaybackInteractionDate: self.date("2026-04-03T11:54:39Z"), dataManager: dataManager)
            self.createTestEpisode(podcast: secondRow, playedUpTo: 403, lastPlaybackInteractionDate: self.date("2026-04-03T11:48:20Z"), dataManager: dataManager)

            let other = self.createTestPodcast(title: "Other Show", dataManager: dataManager)
            self.createTestEpisode(podcast: other, playedUpTo: 600, lastPlaybackInteractionDate: self.date("2026-05-01T10:00:00Z"), dataManager: dataManager)
            self.createTestEpisode(podcast: other, playedUpTo: 600, lastPlaybackInteractionDate: self.date("2026-05-02T10:00:00Z"), dataManager: dataManager)

            let stats = dataManager.playbackPodcastStats(in: self.year)

            XCTAssertEqual(stats.map(\.uuid), [other.uuid, uuid])
            XCTAssertEqual(stats.map(\.playedSeconds), [1200, 949])
            XCTAssertEqual(stats.map(\.episodesPlayed), [2, 2])
            XCTAssertEqual(stats.last?.title, "Optimal Living Daily")
        }
    }

    func testPodcastStatsWithoutDuplicates() throws {
        try runWithDataManager { dataManager in
            let top = self.createTestPodcast(title: "Top Show", dataManager: dataManager)
            self.createTestEpisode(podcast: top, playedUpTo: 1200, lastPlaybackInteractionDate: self.date("2026-02-10T08:00:00Z"), dataManager: dataManager)
            self.createTestEpisode(podcast: top, playedUpTo: 800, lastPlaybackInteractionDate: self.date("2026-03-10T08:00:00Z"), dataManager: dataManager)
            self.createTestEpisode(podcast: top, playedUpTo: 5000, lastPlaybackInteractionDate: self.date("2025-12-31T08:00:00Z"), dataManager: dataManager)

            let second = self.createTestPodcast(title: "Second Show", dataManager: dataManager)
            self.createTestEpisode(podcast: second, playedUpTo: 700, lastPlaybackInteractionDate: self.date("2026-06-01T08:00:00Z"), dataManager: dataManager)
            self.createTestEpisode(podcast: second, playedUpTo: 0, lastPlaybackInteractionDate: self.date("2026-06-02T08:00:00Z"), dataManager: dataManager)

            let unplayed = self.createTestPodcast(title: "Opened Only", dataManager: dataManager)
            self.createTestEpisode(podcast: unplayed, playedUpTo: 0, lastPlaybackInteractionDate: self.date("2026-07-01T08:00:00Z"), dataManager: dataManager)

            let stats = dataManager.playbackPodcastStats(in: self.year)

            XCTAssertEqual(stats.map(\.uuid), [top.uuid, second.uuid])
            XCTAssertEqual(stats.map(\.title), ["Top Show", "Second Show"])
            XCTAssertEqual(stats.map(\.playedSeconds), [2000, 700])
            XCTAssertEqual(stats.map(\.episodesPlayed), [2, 2])
        }
    }
}
