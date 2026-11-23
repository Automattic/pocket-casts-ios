import PocketCastsDataModel
@testable import PocketCastsServer
import XCTest

final class PositionSyncTaskTests: XCTestCase {
    func testSendsPositionAndDurationInWholeSeconds() throws {
        let request = try sentRequest(upTo: 125.7, duration: 3600.4)

        XCTAssertEqual(request.position.value, 125)
        XCTAssertEqual(request.duration, 3600)
    }

    func testLeavesOutDurationThatDoesNotFitInt32() throws {
        for duration in [TimeInterval.infinity, -.infinity, .nan, .greatestFiniteMagnitude] {
            let request = try sentRequest(upTo: 125, duration: duration)

            XCTAssertEqual(request.position.value, 125, "duration: \(duration)")
            XCTAssertEqual(request.duration, 0, "duration: \(duration)")
        }
    }

    func testLeavesOutPositionThatDoesNotFitInt32() throws {
        for upTo in [TimeInterval.infinity, .nan, .greatestFiniteMagnitude] {
            let request = try sentRequest(upTo: upTo, duration: 3600)

            XCTAssertFalse(request.hasPosition, "upTo: \(upTo)")
            XCTAssertEqual(request.duration, 3600, "upTo: \(upTo)")
        }
    }

    private func sentRequest(upTo: TimeInterval, duration: TimeInterval) throws -> Api_UpdateEpisodeRequest {
        let episode = Episode()
        episode.uuid = "episode-uuid"
        episode.podcastUuid = "podcast-uuid"

        var body: Data?
        let urlConnection = URLConnection(mockHandler: { request in
            body = request.httpBody
            let url = try XCTUnwrap(request.url)
            return (nil, HTTPURLResponse(url: url, statusCode: ServerConstants.HttpConstants.ok, httpVersion: nil, headerFields: nil))
        })

        PositionSyncTask(upTo: upTo, duration: duration, episode: episode, urlConnection: urlConnection)
            .apiTokenAcquired(token: "token")

        return try Api_UpdateEpisodeRequest(serializedBytes: XCTUnwrap(body))
    }
}
