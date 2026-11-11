import AVFoundation
import XCTest
@testable import podcasts

final class PlaybackInterruptionTests: XCTestCase {

    override func tearDown() {
        // End the interruption so the shared PlaybackManager isn't left thinking one is in progress
        postInterruption(type: .ended, options: [])
        waitForMainQueue()
        super.tearDown()
    }

    func testInterruptionStopsUpdateTimerSoSleepTimerDoesNotKeepCountingDown() {
        let playbackManager = PlaybackManager.shared
        playbackManager.startUpdateTimer()
        waitForMainQueue()
        XCTAssertNotNil(playbackManager.updateTimer)

        postInterruption(type: .began)
        waitForMainQueue()

        XCTAssertNil(playbackManager.updateTimer)
    }

    // MARK: - Helpers

    private func postInterruption(type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions? = nil) {
        var userInfo: [AnyHashable: Any] = [AVAudioSessionInterruptionTypeKey: NSNumber(value: type.rawValue)]
        if let options {
            userInfo[AVAudioSessionInterruptionOptionKey] = NSNumber(value: options.rawValue)
        }
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: userInfo)
    }

    private func waitForMainQueue() {
        let expectation = expectation(description: "main queue drained")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)
    }
}
