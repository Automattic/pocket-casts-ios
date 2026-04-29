import EventHorizonSDK
import PocketCastsDataModel
import XCTest

@testable import podcasts

class ListeningTimeTrackerTests: XCTestCase {
    private var capturedEvents: [ListeningTimeEvent] = []
    private var now = Date(timeIntervalSince1970: 1_700_000_000)
    private var storage = InMemorySessionStorage()

    private func makeTracker(storage: InMemorySessionStorage? = nil) -> ListeningTimeTracker {
        capturedEvents = []
        if let storage { self.storage = storage }
        let storage = storage ?? self.storage
        return ListeningTimeTracker(
            dateProvider: { self.now },
            uptimeProvider: { self.now.timeIntervalSinceReferenceDate },
            storage: storage,
            send: { event in
                self.capturedEvents.append(event)
            }
        )
    }

    private func makeEpisode(uuid: String = "ep-uuid", podcastUuid: String = "pod-uuid") -> Episode {
        let episode = Episode()
        episode.uuid = uuid
        episode.podcastUuid = podcastUuid
        return episode
    }

    func testStartThenStopEmitsOneEvent() {
        let tracker = makeTracker()
        let episode = makeEpisode()

        tracker.start(episode: episode)
        now = now.addingTimeInterval(12.5)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 1)
        let event = capturedEvents[0]
        XCTAssertEqual(event.episodeUuid, "ep-uuid")
        XCTAssertEqual(event.podcastUuid, "pod-uuid")
        XCTAssertEqual(event.durationMs, 12_500)
        XCTAssertEqual(event.startedAtMs, 1_700_000_000_000)
        XCTAssertFalse(event.eventUuid.isEmpty)
    }

    func testStartIsIdempotentForSameEpisode() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode(uuid: "ep"))
        now = now.addingTimeInterval(5)
        tracker.start(episode: makeEpisode(uuid: "ep"))
        now = now.addingTimeInterval(5)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 1)
        XCTAssertEqual(capturedEvents[0].episodeUuid, "ep")
        XCTAssertEqual(capturedEvents[0].durationMs, 10_000)
    }

    func testStartWithDifferentEpisodeFlushesOldSession() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode(uuid: "A", podcastUuid: "podA"))
        now = now.addingTimeInterval(7)
        tracker.start(episode: makeEpisode(uuid: "B", podcastUuid: "podB"))
        now = now.addingTimeInterval(3)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 2)
        XCTAssertEqual(capturedEvents[0].episodeUuid, "A")
        XCTAssertEqual(capturedEvents[0].podcastUuid, "podA")
        XCTAssertEqual(capturedEvents[0].durationMs, 7_000)
        XCTAssertEqual(capturedEvents[1].episodeUuid, "B")
        XCTAssertEqual(capturedEvents[1].podcastUuid, "podB")
        XCTAssertEqual(capturedEvents[1].durationMs, 3_000)
    }

    func testStopWithoutStartIsNoOp() {
        let tracker = makeTracker()
        tracker.stop()
        XCTAssertTrue(capturedEvents.isEmpty)
    }

    func testStopTwiceIsNoOp() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        now = now.addingTimeInterval(3)
        tracker.stop()
        tracker.stop()
        XCTAssertEqual(capturedEvents.count, 1)
    }

    func testEpisodeCapturedAtStart() {
        let tracker = makeTracker()
        let episodeA = makeEpisode(uuid: "A", podcastUuid: "podA")
        tracker.start(episode: episodeA)
        // Even if some other episode B becomes "current" between start and stop,
        // the event should attribute to A because we captured at start.
        _ = makeEpisode(uuid: "B", podcastUuid: "podB")
        now = now.addingTimeInterval(7)
        tracker.stop()

        XCTAssertEqual(capturedEvents[0].episodeUuid, "A")
        XCTAssertEqual(capturedEvents[0].podcastUuid, "podA")
    }

    func testTwoSessionsHaveDifferentEventUuids() {
        let tracker = makeTracker()

        tracker.start(episode: makeEpisode())
        now = now.addingTimeInterval(2)
        tracker.stop()

        tracker.start(episode: makeEpisode())
        now = now.addingTimeInterval(2)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 2)
        XCTAssertNotEqual(capturedEvents[0].eventUuid, capturedEvents[1].eventUuid)
    }

    func testZeroDurationSessionEmitsNoEvent() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        // No time advance — durationMs == 0, should be filtered out.
        tracker.stop()
        XCTAssertTrue(capturedEvents.isEmpty)
    }

    func testEventUuidIsLowercase() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        now = now.addingTimeInterval(1)
        tracker.stop()

        let uuid = capturedEvents[0].eventUuid
        XCTAssertEqual(uuid, uuid.lowercased())
    }

    // MARK: - Persistence

    func testStartPersistsSession() {
        let tracker = makeTracker()
        XCTAssertNil(storage.data)

        tracker.start(episode: makeEpisode())
        XCTAssertNotNil(storage.data)
    }

    func testStopClearsPersistedSession() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        XCTAssertNotNil(storage.data)

        now = now.addingTimeInterval(5)
        tracker.stop()
        XCTAssertNil(storage.data)
    }

    func testHeartbeatRefreshesPersistedHeartbeatTimestamp() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        let initial = storage.data!

        now = now.addingTimeInterval(45)
        tracker.heartbeatTick()

        XCTAssertNotEqual(initial, storage.data, "heartbeat should rewrite persisted state")
        XCTAssertTrue(capturedEvents.isEmpty, "sub-segment heartbeat should not emit")
    }

    // MARK: - Auto-truncation

    func testHeartbeatEmitsIntermediateEventAtSegmentBoundary() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())

        now = now.addingTimeInterval(TimeInterval(ListeningTimeTracker.segmentDurationMs / 1000))
        tracker.heartbeatTick()

        XCTAssertEqual(capturedEvents.count, 1)
        XCTAssertEqual(capturedEvents[0].durationMs, ListeningTimeTracker.segmentDurationMs)
    }

    func testAutoTruncationStartsNewSegmentForSameEpisode() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode(uuid: "ep"))

        // Advance past segment threshold and tick — emits segment 1, starts segment 2
        now = now.addingTimeInterval(601)
        tracker.heartbeatTick()

        // Listen another 5s and stop — emits segment 2
        now = now.addingTimeInterval(5)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 2)
        XCTAssertEqual(capturedEvents[0].episodeUuid, "ep")
        XCTAssertEqual(capturedEvents[0].durationMs, 601_000)
        XCTAssertEqual(capturedEvents[1].episodeUuid, "ep")
        XCTAssertEqual(capturedEvents[1].durationMs, 5_000)
        XCTAssertNotEqual(capturedEvents[0].eventUuid, capturedEvents[1].eventUuid)
    }

    func testAutoTruncatedSegmentsHaveContiguousStartTimes() {
        let tracker = makeTracker()
        let startMs = Int(now.timeIntervalSince1970 * 1000)
        tracker.start(episode: makeEpisode())

        now = now.addingTimeInterval(600)
        tracker.heartbeatTick()
        now = now.addingTimeInterval(2)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 2)
        XCTAssertEqual(capturedEvents[0].startedAtMs, startMs)
        // Segment 2 begins exactly where segment 1 ended.
        XCTAssertEqual(capturedEvents[1].startedAtMs, startMs + 600_000)
    }

    // MARK: - Recovery

    func testRecoverEmitsPendingSession() {
        // Simulate a previous run that started but never stopped (force-quit).
        let prev = makeTracker()
        prev.start(episode: makeEpisode(uuid: "ep", podcastUuid: "pod"))
        now = now.addingTimeInterval(45)
        prev.heartbeatTick()
        // Storage now has a session with lastHeartbeatAt = startedAt + 45s.
        let persisted = storage.data
        XCTAssertNotNil(persisted)

        // New launch: fresh tracker pointed at the same storage.
        let next = makeTracker(storage: storage)
        // Restore the persisted snapshot since makeTracker reset capturedEvents only.
        storage.data = persisted

        next.recoverPendingSession()

        XCTAssertEqual(capturedEvents.count, 1)
        XCTAssertEqual(capturedEvents[0].episodeUuid, "ep")
        XCTAssertEqual(capturedEvents[0].podcastUuid, "pod")
        XCTAssertEqual(capturedEvents[0].durationMs, 45_000)
        XCTAssertNil(storage.data, "recovery should clear the persisted session")
    }

    func testRecoverSkipsWhenSessionAlreadyActive() {
        // Simulate prior orphan on disk.
        let prev = makeTracker()
        prev.start(episode: makeEpisode(uuid: "orphan"))
        now = now.addingTimeInterval(20)
        prev.heartbeatTick()
        let orphanData = storage.data

        // New launch: start a session BEFORE recovery runs (e.g., lockscreen resume).
        let next = makeTracker(storage: storage)
        storage.data = orphanData
        next.start(episode: makeEpisode(uuid: "fresh"))

        next.recoverPendingSession()

        // No orphan emit — only the in-memory "fresh" session counts.
        XCTAssertTrue(capturedEvents.isEmpty)
    }

    func testRecoverDoesNothingWithEmptyStorage() {
        let tracker = makeTracker()
        tracker.recoverPendingSession()
        XCTAssertTrue(capturedEvents.isEmpty)
    }

    // MARK: - Sanity caps

    func testEmittedDurationIsCappedAtMax() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        // Jump past the cap. Auto-truncation would normally prevent this, but
        // the cap also defends against clock changes and recovered state.
        now = now.addingTimeInterval(TimeInterval(ListeningTimeTracker.maxDurationMs / 1000) + 3600)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 1)
        XCTAssertEqual(capturedEvents[0].durationMs, ListeningTimeTracker.maxDurationMs)
    }
}

// MARK: - Test storage

final class InMemorySessionStorage: SessionStorage {
    var data: Data?
    func load() -> Data? { data }
    func save(_ data: Data) { self.data = data }
    func clear() { self.data = nil }
}
