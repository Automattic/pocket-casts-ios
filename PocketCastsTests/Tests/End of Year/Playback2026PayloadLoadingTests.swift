import Foundation
import PlaybackKit
import PocketCastsServer
import Testing
@testable import podcasts

struct Playback2026PayloadLoadingTests {
    @Test func storiesOpenedAgainDuringTheSyncWaitForIt() async {
        let sync = HeldSync()
        let historySync = Playback2026HistorySync { sync.run() }

        let first = Task { await Self.load(historySync) }
        #expect(await sync.waitForRuns(1, timeout: .seconds(5)))
        let second = Task { await Self.load(historySync) }
        _ = await sync.waitForRuns(2, timeout: .milliseconds(500))
        sync.release()
        _ = await (first.value, second.value)

        #expect(sync.runs == 1)
    }

    @Test func storiesOpenedAfterTheSyncSyncAgain() async {
        let sync = HeldSync(isReleased: true)
        let historySync = Playback2026HistorySync { sync.run() }

        _ = await Self.load(historySync)
        _ = await Self.load(historySync)

        #expect(sync.runs == 2)
    }

    @Test func syncRunsOffTheSwiftConcurrencyThreadPool() async {
        let sync = HeldSync(isReleased: true)
        let historySync = Playback2026HistorySync { sync.run() }

        _ = await Self.load(historySync)

        #expect(sync.queueLabels.count == 1)
        #expect(sync.queueLabels.allSatisfy { !$0.contains("cooperative") }, "ran on \(sync.queueLabels)")
    }

    @Test func payloadIsBuiltAfterTheSyncWithTheArchetype() async {
        let events = Events()
        let historySync = Playback2026HistorySync { events.append("sync") }

        let payload = await Playback2026.makePayload(
            historySync: historySync,
            fetchArchetype: { .collector },
            build: { archetype in
                events.append("build")
                return Self.payload(archetype: archetype)
            }
        )

        #expect(events.all == ["sync", "build"])
        #expect(payload.archetype == .collector)
    }

    private static func load(_ historySync: Playback2026HistorySync) async -> PlaybackPayload {
        await Playback2026.makePayload(historySync: historySync, fetchArchetype: { nil }, build: { payload(archetype: $0) })
    }

    private static func payload(archetype: Playback2026Archetype?) -> PlaybackPayload {
        PlaybackPayload(year: 2026, podcasts: [], monthlySeconds: [], archetype: archetype.map(Playback2026Payload.archetype))
    }
}

/// A sync that records each run and the queue it ran on, and holds every run until released.
private final class HeldSync: @unchecked Sendable {
    private let condition = NSCondition()
    private var isReleased: Bool
    private var count = 0
    private var labels: [String] = []

    init(isReleased: Bool = false) {
        self.isReleased = isReleased
    }

    var runs: Int { condition.withLock { count } }
    var queueLabels: [String] { condition.withLock { labels } }

    func run() {
        condition.lock()
        count += 1
        labels.append(String(cString: __dispatch_queue_get_label(nil)))
        while !isReleased {
            condition.wait()
        }
        condition.unlock()
    }

    func release() {
        condition.withLock {
            isReleased = true
            condition.broadcast()
        }
    }

    func waitForRuns(_ runs: Int, timeout: Duration) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while self.runs < runs {
            guard ContinuousClock.now < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return true
    }
}

private final class Events: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [String] = []

    var all: [String] { lock.withLock { events } }

    func append(_ event: String) {
        lock.withLock { events.append(event) }
    }
}
