import XCTest
@testable import podcasts
@testable import PocketCastsDataModel

final class UpNextSortOptionTests: XCTestCase {

    private func episode(_ uuid: String, published: Date? = nil, duration: Double = 0, added: Date? = nil) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.publishedDate = published
        episode.duration = duration
        episode.addedDate = added
        return episode
    }

    private func date(_ daysFromNow: Double) -> Date {
        Date(timeIntervalSince1970: 1_000_000 + daysFromNow * 86_400)
    }

    func testNewestToOldestSortsByPublishedDateDescending() {
        let episodes = [
            episode("old", published: date(1)),
            episode("new", published: date(3)),
            episode("mid", published: date(2))
        ]

        let sorted = UpNextSortOption.newestToOldest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["new", "mid", "old"])
    }

    func testOldestToNewestSortsByPublishedDateAscending() {
        let episodes = [
            episode("old", published: date(1)),
            episode("new", published: date(3)),
            episode("mid", published: date(2))
        ]

        let sorted = UpNextSortOption.oldestToNewest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["old", "mid", "new"])
    }

    func testShortestToLongestSortsByDurationAscending() {
        let episodes = [
            episode("long", duration: 3_000),
            episode("short", duration: 600),
            episode("medium", duration: 1_800)
        ]

        let sorted = UpNextSortOption.shortestToLongest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["short", "medium", "long"])
    }

    func testLongestToShortestSortsByDurationDescending() {
        let episodes = [
            episode("long", duration: 3_000),
            episode("short", duration: 600),
            episode("medium", duration: 1_800)
        ]

        let sorted = UpNextSortOption.longestToShortest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["long", "medium", "short"])
    }

    func testEpisodesWithoutDurationAlwaysGoToTheBottom() {
        let episodes = [
            episode("noDuration", duration: 0, added: date(1)),
            episode("long", duration: 3_000),
            episode("short", duration: 600)
        ]

        XCTAssertEqual(UpNextSortOption.shortestToLongest.sort(episodes).map { $0.uuid },
                       ["short", "long", "noDuration"])
        XCTAssertEqual(UpNextSortOption.longestToShortest.sort(episodes).map { $0.uuid },
                       ["long", "short", "noDuration"])
    }

    func testEqualDurationsBreakTieByAddedDate() {
        let episodes = [
            episode("addedLater", duration: 1_000, added: date(2)),
            episode("addedEarlier", duration: 1_000, added: date(1))
        ]

        let sorted = UpNextSortOption.shortestToLongest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["addedEarlier", "addedLater"])
    }
}
