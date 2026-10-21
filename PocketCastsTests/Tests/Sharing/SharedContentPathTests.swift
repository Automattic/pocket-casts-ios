import XCTest
@testable import podcasts

final class SharedContentPathTests: XCTestCase {
    private let podcastUuid = "f5b97290-0422-012e-f9a0-00163e1b201c"
    private let episodeUuid = "7a1c5a40-9d2b-4a3e-8d31-0b6f3f6a1c11"

    func testPodcastPath() {
        XCTAssertEqual(
            AppDelegate.sharedContent(forPath: "social/share/show/podcast/radiolab/\(podcastUuid)"),
            .podcast(uuid: podcastUuid)
        )
    }

    func testPodcastPathWithTrailingSlash() {
        XCTAssertEqual(
            AppDelegate.sharedContent(forPath: "social/share/show/podcast/radiolab/\(podcastUuid)/"),
            .podcast(uuid: podcastUuid)
        )
    }

    func testPodcastPathWithMultipleTrailingSlashes() {
        XCTAssertEqual(
            AppDelegate.sharedContent(forPath: "/podcast/radiolab/\(podcastUuid)//"),
            .podcast(uuid: podcastUuid)
        )
    }

    func testPodcastPathWithoutSlug() {
        XCTAssertEqual(AppDelegate.sharedContent(forPath: "/podcast/\(podcastUuid)"), .podcast(uuid: podcastUuid))
        XCTAssertEqual(AppDelegate.sharedContent(forPath: "/podcast/\(podcastUuid)/"), .podcast(uuid: podcastUuid))
    }

    func testPrivatePath() {
        XCTAssertEqual(AppDelegate.sharedContent(forPath: "/private/\(podcastUuid)"), .podcast(uuid: podcastUuid))
        XCTAssertEqual(AppDelegate.sharedContent(forPath: "/private/\(podcastUuid)/"), .podcast(uuid: podcastUuid))
    }

    func testEpisodePath() {
        let path = "/podcast/radiolab/\(podcastUuid)/some-episode/\(episodeUuid)"
        XCTAssertEqual(
            AppDelegate.sharedContent(forPath: path),
            .episode(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        )
    }

    func testEpisodePathWithTrailingSlash() {
        let path = "/podcast/radiolab/\(podcastUuid)/some-episode/\(episodeUuid)/"
        XCTAssertEqual(
            AppDelegate.sharedContent(forPath: path),
            .episode(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        )
    }

    func testPathsWithoutPodcastSegmentAreNotHandled() {
        XCTAssertNil(AppDelegate.sharedContent(forPath: "social/share/show/abc123"))
        XCTAssertNil(AppDelegate.sharedContent(forPath: "social/share/show/abc123/"))
        XCTAssertNil(AppDelegate.sharedContent(forPath: "/podcast/"))
    }
}
