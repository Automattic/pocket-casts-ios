import EventHorizonSDK
import PocketCastsDataModel
import XCTest

@testable import podcasts

class ListeningTimeTrackerTests: XCTestCase {
    private var capturedEvents: [ListeningTimeEvent] = []
    private var now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTracker() -> ListeningTimeTracker {
        capturedEvents = []
        return ListeningTimeTracker(
            dateProvider: { self.now },
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
}
