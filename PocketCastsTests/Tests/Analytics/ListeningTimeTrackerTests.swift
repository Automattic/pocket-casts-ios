import XCTest
import PocketCastsDataModel

@testable import podcasts

class ListeningTimeTrackerTests: XCTestCase {
    private var capturedEvents: [(event: AnalyticsEvent, properties: [AnyHashable: Any]?)] = []
    private var now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeTracker() -> ListeningTimeTracker {
        capturedEvents = []
        return ListeningTimeTracker(
            dateProvider: { self.now },
            track: { event, properties in
                self.capturedEvents.append((event, properties))
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
        XCTAssertEqual(event.event, .listeningTime)
        let props = event.properties
        XCTAssertEqual(props?["episode_uuid"] as? String, "ep-uuid")
        XCTAssertEqual(props?["podcast_uuid"] as? String, "pod-uuid")
        XCTAssertEqual(props?["duration_ms"] as? Int64, 12_500)
        XCTAssertEqual(props?["started_at_ms"] as? Int64, 1_700_000_000_000)
        XCTAssertNotNil(props?["event_uuid"] as? String)
        XCTAssertNotNil(props?["device_type"] as? DeviceType)
    }

    func testStartIsIdempotentForSameEpisode() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode(uuid: "ep"))
        now = now.addingTimeInterval(5)
        tracker.start(episode: makeEpisode(uuid: "ep"))
        now = now.addingTimeInterval(5)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 1)
        XCTAssertEqual(capturedEvents[0].properties?["episode_uuid"] as? String, "ep")
        XCTAssertEqual(capturedEvents[0].properties?["duration_ms"] as? Int64, 10_000)
    }

    func testStartWithDifferentEpisodeFlushesOldSession() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode(uuid: "A", podcastUuid: "podA"))
        now = now.addingTimeInterval(7)
        tracker.start(episode: makeEpisode(uuid: "B", podcastUuid: "podB"))
        now = now.addingTimeInterval(3)
        tracker.stop()

        XCTAssertEqual(capturedEvents.count, 2)
        XCTAssertEqual(capturedEvents[0].properties?["episode_uuid"] as? String, "A")
        XCTAssertEqual(capturedEvents[0].properties?["podcast_uuid"] as? String, "podA")
        XCTAssertEqual(capturedEvents[0].properties?["duration_ms"] as? Int64, 7_000)
        XCTAssertEqual(capturedEvents[1].properties?["episode_uuid"] as? String, "B")
        XCTAssertEqual(capturedEvents[1].properties?["podcast_uuid"] as? String, "podB")
        XCTAssertEqual(capturedEvents[1].properties?["duration_ms"] as? Int64, 3_000)
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

        XCTAssertEqual(capturedEvents[0].properties?["episode_uuid"] as? String, "A")
        XCTAssertEqual(capturedEvents[0].properties?["podcast_uuid"] as? String, "podA")
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
        let uuid1 = capturedEvents[0].properties?["event_uuid"] as? String
        let uuid2 = capturedEvents[1].properties?["event_uuid"] as? String
        XCTAssertNotNil(uuid1)
        XCTAssertNotNil(uuid2)
        XCTAssertNotEqual(uuid1, uuid2)
    }

    func testZeroDurationSessionEmitsNoEvent() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        // No time advance — duration_ms == 0, should be filtered out.
        tracker.stop()
        XCTAssertTrue(capturedEvents.isEmpty)
    }

    func testEventUuidIsLowercase() {
        let tracker = makeTracker()
        tracker.start(episode: makeEpisode())
        now = now.addingTimeInterval(1)
        tracker.stop()

        let uuid = capturedEvents[0].properties?["event_uuid"] as? String
        XCTAssertEqual(uuid, uuid?.lowercased())
    }
}
