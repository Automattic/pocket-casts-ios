import Foundation
import Testing
import UIKit
import PocketCastsUtils
@testable import podcasts

@MainActor
struct Playback2026AvailabilityTests {
    private let notificationCenter = NotificationCenter()

    @Test func reportsWhetherPlaybackIsAvailableEachTimeAFlagChanges() async {
        var isAvailable = false
        var received: [Bool] = []
        let observation = Playback2026.observeAvailability(notificationCenter: notificationCenter, isAvailable: { isAvailable }) {
            received.append($0)
        }

        notificationCenter.post(name: .featureFlagsDidChange, object: nil)
        await mainQueue()
        isAvailable = true
        notificationCenter.post(name: .featureFlagsDidChange, object: nil)
        await mainQueue()
        isAvailable = false
        notificationCenter.post(name: .featureFlagsDidChange, object: nil)
        await mainQueue()

        #expect(received == [false, true, false])
        observation.cancel()
    }

    @Test func ignoresOtherNotifications() async {
        var received: [Bool] = []
        let observation = Playback2026.observeAvailability(notificationCenter: notificationCenter, isAvailable: { true }) {
            received.append($0)
        }

        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await mainQueue()

        #expect(received.isEmpty)
        observation.cancel()
    }

    @Test func stopsWhenCancelled() async {
        var received: [Bool] = []
        let observation = Playback2026.observeAvailability(notificationCenter: notificationCenter, isAvailable: { true }) {
            received.append($0)
        }

        observation.cancel()
        notificationCenter.post(name: .featureFlagsDidChange, object: nil)
        await mainQueue()

        #expect(received.isEmpty)
    }

    private func mainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }
}
