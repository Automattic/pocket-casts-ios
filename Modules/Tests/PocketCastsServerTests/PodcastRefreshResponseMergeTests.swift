import XCTest
@testable import PocketCastsServer

final class PodcastRefreshResponseMergeTests: XCTestCase {

    func testMergedCombinesTheUpdatesOfEveryBatch() {
        let merged = PodcastRefreshResponse.merged([
            response(updates: ["podcast-1": ["episode-1"], "podcast-2": ["episode-2", "episode-3"]]),
            response(updates: ["podcast-3": ["episode-4"]])
        ])

        XCTAssertTrue(merged.success())
        XCTAssertEqual(merged.result?.podcastUpdates?.keys.sorted(), ["podcast-1", "podcast-2", "podcast-3"])
        XCTAssertEqual(merged.result?.podcastUpdates?["podcast-2"]?.compactMap(\.uuid), ["episode-2", "episode-3"])
    }

    func testMergedFailsWhenAnyBatchFails() {
        let merged = PodcastRefreshResponse.merged([
            response(updates: ["podcast-1": ["episode-1"]]),
            .failedResponse()
        ])

        XCTAssertFalse(merged.success())
        XCTAssertNil(merged.result)
    }

    func testMergedReturnsASingleResponseUnchanged() {
        var single = response(updates: [:])
        single.message = "Single"

        XCTAssertEqual(PodcastRefreshResponse.merged([single]).message, "Single")
    }

    func testMergedTreatsBatchesWithoutUpdatesAsEmpty() {
        var empty = PodcastRefreshResponse()
        empty.status = "ok"

        let merged = PodcastRefreshResponse.merged([empty, response(updates: ["podcast-1": ["episode-1"]])])

        XCTAssertTrue(merged.success())
        XCTAssertEqual(merged.result?.podcastUpdates?.keys.sorted(), ["podcast-1"])
    }

    private func response(updates: [String: [String]]) -> PodcastRefreshResponse {
        var response = PodcastRefreshResponse()
        response.status = "ok"
        response.result = RefreshResult(podcastUpdates: updates.mapValues { uuids in
            uuids.map { uuid in
                var episode = RefreshEpisode()
                episode.uuid = uuid
                return episode
            }
        })
        return response
    }
}
