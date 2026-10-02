import XCTest
@testable import podcasts

final class PlayRequestPendingTests: XCTestCase {

    func testPlayRequestIsPendingWhileAudioSessionActivates() {
        XCTAssertTrue(PlaybackManager.isPlayRequestPending(isAboutToPlay: true, playerShouldBePlaying: false))
    }

    func testPlayRequestIsNotPendingOnceThePlayerStartsPlaying() {
        XCTAssertFalse(PlaybackManager.isPlayRequestPending(isAboutToPlay: true, playerShouldBePlaying: true))
    }

    func testPlayRequestIsNotPendingWhenPaused() {
        XCTAssertFalse(PlaybackManager.isPlayRequestPending(isAboutToPlay: false, playerShouldBePlaying: false))
    }

    func testPlayRequestIsNotPendingWhenPlaying() {
        XCTAssertFalse(PlaybackManager.isPlayRequestPending(isAboutToPlay: false, playerShouldBePlaying: true))
    }
}
