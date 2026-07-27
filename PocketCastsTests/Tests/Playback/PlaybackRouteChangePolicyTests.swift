import AVFoundation
import XCTest

@testable import podcasts

final class PlaybackRouteChangePolicyTests: XCTestCase {
    func testOldDeviceUnavailablePausesPlayback() {
        XCTAssertEqual(
            PlaybackManager.routeChangeDecision(for: .oldDeviceUnavailable),
            .pause
        )
    }

    func testConnectingOrReconfiguringADeviceRestartsPlaybackAndNowPlayingData() {
        let reasons: [AVAudioSession.RouteChangeReason] = [
            .newDeviceAvailable,
            .override,
            .categoryChange
        ]

        for reason in reasons {
            XCTAssertEqual(
                PlaybackManager.routeChangeDecision(for: reason),
                .restart(updateNowPlaying: true)
            )
        }
    }

    func testRouteConfigurationChangeRestartsPlaybackWithoutRebuildingNowPlayingData() {
        XCTAssertEqual(
            PlaybackManager.routeChangeDecision(for: .routeConfigurationChange),
            .restart(updateNowPlaying: false)
        )
    }

    func testUnrelatedRouteChangesDoNotAffectPlayback() {
        let reasons: [AVAudioSession.RouteChangeReason] = [
            .unknown,
            .wakeFromSleep,
            .noSuitableRouteForCategory
        ]

        for reason in reasons {
            XCTAssertNil(PlaybackManager.routeChangeDecision(for: reason))
        }
    }
}
