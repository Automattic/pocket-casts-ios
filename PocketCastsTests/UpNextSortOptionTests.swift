import XCTest
@testable import podcasts
@testable import PocketCastsDataModel

final class UpNextSortOptionTests: XCTestCase {

    private func episode(_ uuid: String, published: Date? = nil, duration: Double = 0, playedUpTo: Double = 0, added: Date? = nil) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.publishedDate = published
        episode.duration = duration
        episode.playedUpTo = playedUpTo
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

    func testEqualPublishedDatesBreakTieByAddedDate() {
        let episodes = [
            episode("addedLater", published: date(1), added: date(2)),
            episode("addedEarlier", published: date(1), added: date(1))
        ]

        XCTAssertEqual(UpNextSortOption.newestToOldest.sort(episodes).map { $0.uuid },
                       ["addedEarlier", "addedLater"])
        XCTAssertEqual(UpNextSortOption.oldestToNewest.sort(episodes).map { $0.uuid },
                       ["addedEarlier", "addedLater"])
    }

    func testEpisodesWithoutPublishedDateGoToTheBottom() {
        let episodes = [
            episode("noDate", published: nil, added: date(1)),
            episode("new", published: date(3)),
            episode("old", published: date(1))
        ]

        XCTAssertEqual(UpNextSortOption.newestToOldest.sort(episodes).map { $0.uuid },
                       ["new", "old", "noDate"])
        XCTAssertEqual(UpNextSortOption.oldestToNewest.sort(episodes).map { $0.uuid },
                       ["old", "new", "noDate"])
    }

    func testShortestToLongestSortsByTimeRemainingAscending() {
        let episodes = [
            episode("short", duration: 600),
            episode("medium", duration: 1_800),
            episode("long", duration: 3_000)
        ]

        let sorted = UpNextSortOption.shortestToLongest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["short", "medium", "long"])
    }

    func testLongestToShortestSortsByTimeRemainingDescending() {
        let episodes = [
            episode("short", duration: 600),
            episode("medium", duration: 1_800),
            episode("long", duration: 3_000)
        ]

        let sorted = UpNextSortOption.longestToShortest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["long", "medium", "short"])
    }

    func testTimeRemainingAccountsForAlreadyPlayedTime() {
        // A long episode that's almost finished has less time remaining than a
        // short, unplayed one, so it should sort first when shortest-to-longest.
        let episodes = [
            episode("longAlmostDone", duration: 3_000, playedUpTo: 2_900), // 100 remaining
            episode("shortUnplayed", duration: 600, playedUpTo: 0),        // 600 remaining
            episode("midHalfPlayed", duration: 1_800, playedUpTo: 900)     // 900 remaining
        ]

        XCTAssertEqual(UpNextSortOption.shortestToLongest.sort(episodes).map { $0.uuid },
                       ["longAlmostDone", "shortUnplayed", "midHalfPlayed"])
        XCTAssertEqual(UpNextSortOption.longestToShortest.sort(episodes).map { $0.uuid },
                       ["midHalfPlayed", "shortUnplayed", "longAlmostDone"])
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

    func testEqualTimeRemainingBreakTieByAddedDate() {
        let episodes = [
            episode("addedLater", duration: 2_000, playedUpTo: 1_000, added: date(2)),  // 1_000 remaining
            episode("addedEarlier", duration: 1_000, playedUpTo: 0, added: date(1))     // 1_000 remaining
        ]

        let sorted = UpNextSortOption.shortestToLongest.sort(episodes).map { $0.uuid }

        XCTAssertEqual(sorted, ["addedEarlier", "addedLater"])
    }
}
