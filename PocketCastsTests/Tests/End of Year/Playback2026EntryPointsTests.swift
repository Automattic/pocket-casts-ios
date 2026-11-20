import Foundation
import Testing
import PocketCastsServer
@testable import podcasts

struct Playback2026EntryPointsTests {
    @Test(arguments: [false, true], [false, true])
    func entryPointsNeedTheFlagAndListening(isAvailable: Bool, isEligible: Bool) {
        #expect(Playback2026.showsEntryPoints(isAvailable: isAvailable, isEligible: isEligible) == (isAvailable && isEligible))
    }

    @Test(arguments: [false, true], [false, true])
    func sheetShowsOnceWhereTheEntryPointsShow(showsEntryPoints: Bool, hasShownSheet: Bool) {
        #expect(Playback2026.shouldShowSheet(showsEntryPoints: showsEntryPoints, hasShownSheet: hasShownSheet) == (showsEntryPoints && !hasShownSheet))
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct Playback2026EligibilityTests {
    private let center = NotificationCenter()
    private let queue = DispatchQueue(label: "Playback2026EligibilityTests")

    static let rechecks: [Notification.Name] = [
        ServerNotifications.syncCompleted,
        .userSignedIn,
        Constants.Notifications.playbackPaused,
        Constants.Notifications.playbackEnded,
        Constants.Notifications.playbackTrackChanged
    ]

    @Test func isNotEligibleBeforeTheFirstCheck() async {
        let database = FakeDatabase(hasListened: true)
        let eligibility = makeEligibility(database)

        #expect(!eligibility.isEligible)

        eligibility.start()
        await firstCheck(of: eligibility)

        #expect(eligibility.isEligible)
        #expect(database.checks == 1)
    }

    @Test func isNotEligibleWithoutListening() async {
        let eligibility = makeEligibility(FakeDatabase(hasListened: false))

        eligibility.start()
        await firstCheck(of: eligibility)

        #expect(!eligibility.isEligible)
    }

    @Test func runsWhatWaitsForTheFirstCheckOnceItIsDone() async {
        let eligibility = makeEligibility(FakeDatabase(hasListened: false))
        var calls = 0
        eligibility.whenChecked { calls += 1 }

        eligibility.start()
        await firstCheck(of: eligibility)
        #expect(calls == 1)

        eligibility.whenChecked { calls += 1 }
        #expect(calls == 2)
    }

    @Test(arguments: rechecks)
    func becomesEligibleAfter(_ notification: Notification.Name) async {
        let database = FakeDatabase(hasListened: false)
        let eligibility = makeEligibility(database)
        eligibility.start()
        await firstCheck(of: eligibility)
        #expect(!eligibility.isEligible)

        database.hasListened = true
        await didChange(afterPosting: notification)

        #expect(eligibility.isEligible)
        #expect(database.checks == 2)
    }

    @Test func stopsCheckingOnceEligible() async {
        let database = FakeDatabase(hasListened: true)
        let eligibility = makeEligibility(database)
        eligibility.start()
        await firstCheck(of: eligibility)

        for notification in Self.rechecks {
            center.post(name: notification, object: nil)
        }
        queue.sync {}

        #expect(database.checks == 1)
    }

    @Test func startsOnce() async {
        let database = FakeDatabase(hasListened: false)
        let eligibility = makeEligibility(database)

        eligibility.start()
        eligibility.start()
        await firstCheck(of: eligibility)
        queue.sync {}

        #expect(database.checks == 1)
    }

    private func makeEligibility(_ database: FakeDatabase) -> Playback2026Eligibility {
        Playback2026Eligibility(notificationCenter: center, queue: queue, check: { database.check() })
    }

    private func firstCheck(of eligibility: Playback2026Eligibility) async {
        await withCheckedContinuation { continuation in
            eligibility.whenChecked { continuation.resume() }
        }
    }

    private func didChange(afterPosting notification: Notification.Name) async {
        let center = center
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let observation = Observation()
            observation.token = center.addObserver(forName: Playback2026Eligibility.didChange, object: nil, queue: .main) { _ in
                observation.token.map(center.removeObserver)
                continuation.resume()
            }
            center.post(name: notification, object: nil)
        }
    }
}

private final class Observation: @unchecked Sendable {
    var token: NSObjectProtocol?
}

private final class FakeDatabase: @unchecked Sendable {
    private let lock = NSLock()
    private var _hasListened: Bool
    private var _checks = 0

    init(hasListened: Bool) {
        _hasListened = hasListened
    }

    var hasListened: Bool {
        get { lock.withLock { _hasListened } }
        set { lock.withLock { _hasListened = newValue } }
    }

    var checks: Int {
        lock.withLock { _checks }
    }

    func check() -> Bool {
        lock.withLock {
            _checks += 1
            return _hasListened
        }
    }
}
