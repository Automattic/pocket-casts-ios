@testable import PocketCastsServer
import SwiftProtobuf
import XCTest

final class OnDemandTranscriptServiceTests: XCTestCase {
    private func makeService(mockHandler: @escaping MockRequestHandler.Handler) -> OnDemandTranscriptService {
        OnDemandTranscriptService(tokenHelper: TokenHelper(urlConnection: URLConnection(mockHandler: mockHandler)))
    }

    func testRequestSendsProtobufAndMapsQueuedResponse() async throws {
        var capturedRequest: URLRequest?
        let service = makeService { request in
            capturedRequest = request
            var body = Api_OnDemandTranscriptResponse()
            body.outcome = .queued
            body.reason = .reasonUnspecified
            body.enablement = .enabled
            body.newlyQueuedCount = 4
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (try body.serializedData(), response)
        }

        let result = try await service.requestTranscript(podcastUUID: "podcast-id", episodeUUID: "episode-id")

        XCTAssertEqual(capturedRequest?.url?.absoluteString, ServerConstants.Urls.api() + "user/transcript/on_demand")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/x-protobuf")
        let requestBody = try Api_OnDemandTranscriptRequest(serializedBytes: XCTUnwrap(capturedRequest?.httpBody))
        XCTAssertEqual(requestBody.podcastUuid, "podcast-id")
        XCTAssertEqual(requestBody.episodeUuid, "episode-id")
        XCTAssertEqual(
            result,
            OnDemandTranscriptResponse(
                outcome: .queued,
                reason: .unspecified,
                enablement: .enabled,
                newlyQueuedCount: 4
            )
        )
    }

    func testRequestMapsNotEligibleDomainResponse() async throws {
        let service = makeService { request in
            var body = Api_OnDemandTranscriptResponse()
            body.outcome = .notEligible
            body.reason = .podcastDisallowed
            body.enablement = .notEnabled
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (try body.serializedData(), response)
        }

        let result = try await service.requestTranscript(podcastUUID: "podcast-id", episodeUUID: "episode-id")

        XCTAssertEqual(result.outcome, .notEligible)
        XCTAssertEqual(result.reason, .podcastDisallowed)
        XCTAssertEqual(result.enablement, .notEnabled)
    }

    func testRequestMapsHTTPFailures() async {
        for (statusCode, expectedError) in [
            (400, OnDemandTranscriptServiceError.malformedRequest),
            (403, .accessDenied),
            (404, .notFound),
            (429, .throttled),
            (503, .transient)
        ] {
            let service = makeService { request in
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                return (nil, response)
            }

            do {
                _ = try await service.requestTranscript(podcastUUID: "podcast-id", episodeUUID: "episode-id")
                XCTFail("Expected HTTP \(statusCode) to throw")
            } catch {
                XCTAssertEqual(error as? OnDemandTranscriptServiceError, expectedError)
            }
        }
    }
}
