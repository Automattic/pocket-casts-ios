import XCTest

@testable import PocketCastsDataModel

/// Equality/hashing tests for `Episode` and `UserEpisode`.
///
/// Both types are `NSObject` subclasses conforming to `BaseEpisode`, so their
/// `isEqual(_:)` overrides back Swift's `==`, `Set`, `contains(_:)`, and
/// `firstIndex(of:)`. A regression here (e.g. casting to the wrong sibling
/// type) silently breaks collection operations rather than failing to compile.
class EpisodeEqualityTests: XCTestCase {
    private func makeUserEpisode(uuid: String, id: Int64 = 0) -> UserEpisode {
        let episode = UserEpisode()
        episode.uuid = uuid
        episode.id = id
        return episode
    }

    private func makeEpisode(uuid: String, id: Int64 = 0) -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.id = id
        return episode
    }

    // MARK: - UserEpisode

    func testUserEpisodesWithSameUuidAreEqual() {
        let a = makeUserEpisode(uuid: "file-123", id: 1)
        let b = makeUserEpisode(uuid: "file-123", id: 1)

        XCTAssertEqual(a, b)
    }

    func testUserEpisodeIsEqualToItself() {
        let a = makeUserEpisode(uuid: "file-123", id: 1)

        XCTAssertEqual(a, a)
    }

    func testUserEpisodesWithDifferentUuidsAreNotEqual() {
        let a = makeUserEpisode(uuid: "file-123", id: 1)
        let b = makeUserEpisode(uuid: "file-456", id: 2)

        XCTAssertNotEqual(a, b)
    }

    func testUserEpisodeContainsFindsEqualInstance() {
        let a = makeUserEpisode(uuid: "file-123", id: 1)
        let b = makeUserEpisode(uuid: "file-123", id: 1)

        XCTAssertTrue([a].contains(b))
        XCTAssertEqual([a].firstIndex(of: b), 0)
    }

    func testUserEpisodeSetDeduplicatesEqualInstances() {
        let a = makeUserEpisode(uuid: "file-123", id: 1)
        let b = makeUserEpisode(uuid: "file-123", id: 1)

        let set: Set<UserEpisode> = [a, b]

        XCTAssertEqual(set.count, 1)
    }

    func testUserEpisodeIsNotEqualToNonEpisodeObjects() {
        let a = makeUserEpisode(uuid: "file-123", id: 1)

        XCTAssertFalse(a.isEqual("file-123"))
        XCTAssertFalse(a.isEqual(nil))
    }

    // MARK: - Cross type isolation

    func testUserEpisodeIsNotEqualToEpisodeWithSameUuid() {
        let userEpisode = makeUserEpisode(uuid: "shared-uuid", id: 1)
        let episode = makeEpisode(uuid: "shared-uuid", id: 1)

        XCTAssertNotEqual(userEpisode, episode)
        XCTAssertNotEqual(episode, userEpisode)
    }

    // MARK: - Episode

    func testEpisodesWithSameUuidAreEqual() {
        let a = makeEpisode(uuid: "ep-123", id: 1)
        let b = makeEpisode(uuid: "ep-123", id: 1)

        XCTAssertEqual(a, b)
        XCTAssertTrue([a].contains(b))
    }

    func testEpisodesWithDifferentUuidsAreNotEqual() {
        let a = makeEpisode(uuid: "ep-123", id: 1)
        let b = makeEpisode(uuid: "ep-456", id: 2)

        XCTAssertNotEqual(a, b)
    }
}
