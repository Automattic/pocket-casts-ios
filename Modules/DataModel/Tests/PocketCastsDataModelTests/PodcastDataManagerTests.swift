import XCTest
import SQLite3
@testable import PocketCastsDataModel

final class PodcastDataManagerTests: XCTestCase {
    private func setupDatabase() throws -> DataManager {
        DataManager.newTestDataManager()
    }

    private func setupDataManager() throws -> DataManager {
        let dataManager = try setupDatabase()
        let podcastCount = 1000
        let episodeCount = 50

        (0...podcastCount).forEach { idx in
            let podcast = Podcast()
            podcast.uuid = "\(idx)"
            podcast.addedDate = Date()

            dataManager.save(podcast: podcast)

            (0...episodeCount).forEach { _ in
                let episode = Episode()
                episode.uuid = UUID().uuidString
                episode.addedDate = Date()
                episode.podcastUuid = podcast.uuid

                dataManager.save(episode: episode)
            }
        }

        return dataManager
    }

    func testFindPodcastPerformance() throws {
        let dataManager = try setupDataManager()

        self.measure {
            (0...10000).forEach { _ in
                let random = Int.random(in: 0...1000)
                _ = dataManager.findPodcast(uuid: "\(random)")
            }
        }
    }

    func testEpisodesInfoCacheStaleNeverPolicyIsFalse() throws {
        let podcast = Podcast()
        podcast.episodesInfoCacheReloadPolicy = Podcast.EpisodeInfoCacheReloadPolicy.never.rawValue

        let now = ISO8601DateFormatter().date(from: "2024-01-15T12:00:00Z")!

        let oldDate = Calendar.current.date(byAdding: .year, value: -5, to: now)!

        XCTAssertFalse(podcast.isEpisodesInfoCacheStale(since: oldDate, now: now))
    }

    func testEpisodesInfoCacheStaleWeeklyPolicyThresholds() throws {
        let podcast = Podcast()
        podcast.episodesInfoCacheReloadPolicy = Podcast.EpisodeInfoCacheReloadPolicy.weekly.rawValue

        let now = ISO8601DateFormatter().date(from: "2024-01-15T12:00:00Z")!

        let sixDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: now)!
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: now)!

        XCTAssertFalse(podcast.isEpisodesInfoCacheStale(since: sixDaysAgo, now: now))
        XCTAssertTrue(podcast.isEpisodesInfoCacheStale(since: eightDaysAgo, now: now))
    }

    func testEpisodesInfoCacheStaleMonthlyPolicyThresholds() throws {
        let podcast = Podcast()
        podcast.episodesInfoCacheReloadPolicy = Podcast.EpisodeInfoCacheReloadPolicy.monthly.rawValue

        let now = ISO8601DateFormatter().date(from: "2024-03-31T12:00:00Z")!

        let justUnderOneMonthAgo = Calendar.current.date(byAdding: .day, value: -29, to: now)!
        let overOneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!.addingTimeInterval(-3600) // 1 hour more than one month ago

        XCTAssertFalse(podcast.isEpisodesInfoCacheStale(since: justUnderOneMonthAgo, now: now))
        XCTAssertTrue(podcast.isEpisodesInfoCacheStale(since: overOneMonthAgo, now: now))
    }
}
