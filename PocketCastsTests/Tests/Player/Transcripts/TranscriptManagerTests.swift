import XCTest
@testable import PocketCastsDataModel
@testable import PocketCastsServer
@testable import podcasts

final class TranscriptManagerTests: XCTestCase {
    actor MockOnDemandService: OnDemandTranscriptRequesting {
        private(set) var requestCount = 0
        var result: Result<OnDemandTranscriptResponse, Error>

        init(result: Result<OnDemandTranscriptResponse, Error>) {
            self.result = result
        }

        func requestTranscript(podcastUUID: String, episodeUUID: String) async throws -> OnDemandTranscriptResponse {
            requestCount += 1
            return try result.get()
        }
    }

    class MockShowCoordinator: ShowInfoCoordinating {
        func loadShowNotes(podcastUuid: String, episodeUuid: String) async throws -> String {
            return ""
        }

        func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String) async throws -> URL? {
            return nil
        }

        func loadChapters(podcastUuid: String, episodeUuid: String) async throws -> ([Episode.Metadata.EpisodeChapter]?, [podcasts.PodcastIndexChapter]?, [GeneratedChapter]?) {
            return (nil, nil, nil)
        }

        func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            guard let transcriptURL = Bundle(for: Self.self).url(forResource: "sample", withExtension: "vtt") else {
                return (transcripts: [], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
            }
            let transcript = Episode.Metadata.Transcript(url: transcriptURL.absoluteString, type: "text/vtt", language: nil)
            return (transcripts: [transcript], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
        }
    }

    class GeneratedMockShowCoordinator: MockShowCoordinator {
        override func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            guard let transcriptURL = Bundle(for: Self.self).url(forResource: "sample", withExtension: "vtt") else {
                return (transcripts: [], hasGeneratedTranscripts: true, isDisplayingGeneratedTranscript: true)
            }
            let transcript = Episode.Metadata.Transcript(url: transcriptURL.absoluteString, type: "text/vtt", language: nil)
            return (transcripts: [transcript], hasGeneratedTranscripts: true, isDisplayingGeneratedTranscript: true)
        }
    }

    class EmptyMockShowCoordinator: MockShowCoordinator {
        override func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            guard let transcriptURL = Bundle(for: Self.self).url(forResource: "empty_sample", withExtension: "vtt") else {
                return (transcripts: [], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
            }
            let transcript = Episode.Metadata.Transcript(url: transcriptURL.absoluteString, type: "text/vtt", language: nil)
            return (transcripts: [transcript], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
        }
    }

    class MissingMockShowCoordinator: MockShowCoordinator {
        override func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            (transcripts: [], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
        }
    }

    class FailingMockShowCoordinator: MockShowCoordinator {
        override func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            throw URLError(.notConnectedToInternet)
        }
    }

    func testLoadingTranscript() async throws {
        let mockShowCoordinator = MockShowCoordinator()
        let manager = TranscriptManager(episodeUUID: UUID().uuidString, podcastUUID: UUID().uuidString, showCoordinator: mockShowCoordinator)

        let model = try await manager.loadTranscript()

        XCTAssertFalse(model.cues.isEmpty)
        XCTAssertEqual(model.cues.count, 13)
    }

    func testIsDisplayingGeneratedTranscriptPropagatesTrue() async throws {
        let manager = TranscriptManager(episodeUUID: UUID().uuidString, podcastUUID: UUID().uuidString, showCoordinator: GeneratedMockShowCoordinator())
        _ = try await manager.loadTranscript()
        XCTAssertTrue(manager.isDisplayingGeneratedTranscript)
        XCTAssertTrue(manager.hasGeneratedTranscripts)
    }

    func testIsDisplayingGeneratedTranscriptPropagatesFalse() async throws {
        let manager = TranscriptManager(episodeUUID: UUID().uuidString, podcastUUID: UUID().uuidString, showCoordinator: MockShowCoordinator())
        _ = try await manager.loadTranscript()
        XCTAssertFalse(manager.isDisplayingGeneratedTranscript)
        XCTAssertFalse(manager.hasGeneratedTranscripts)
    }

    func testEmptyLoadingTranscript() async {
        let mockShowCoordinator = EmptyMockShowCoordinator()
        let manager = TranscriptManager(episodeUUID: UUID().uuidString, podcastUUID: UUID().uuidString, showCoordinator: mockShowCoordinator)

        do {
            _ = try await manager.loadTranscript()
        } catch {
            XCTAssertTrue(error is TranscriptError)
        }
    }

    func testLoadingTranscriptPropagatesMetadataFailure() async {
        let manager = TranscriptManager(
            episodeUUID: UUID().uuidString,
            podcastUUID: UUID().uuidString,
            showCoordinator: FailingMockShowCoordinator()
        )

        do {
            _ = try await manager.loadTranscript()
            XCTFail("Expected metadata failure")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testOnDemandEligibilityAllowsPlusAndPatronOnly() {
        XCTAssertTrue(OnDemandTranscriptEligibility.isEligible(isLoggedIn: true, hasActiveSubscription: true, tier: .plus, flagEnabled: true))
        XCTAssertTrue(OnDemandTranscriptEligibility.isEligible(isLoggedIn: true, hasActiveSubscription: true, tier: .patron, flagEnabled: true))
        XCTAssertFalse(OnDemandTranscriptEligibility.isEligible(isLoggedIn: true, hasActiveSubscription: false, tier: .none, flagEnabled: true))
        XCTAssertFalse(OnDemandTranscriptEligibility.isEligible(isLoggedIn: false, hasActiveSubscription: true, tier: .plus, flagEnabled: true))
        XCTAssertFalse(OnDemandTranscriptEligibility.isEligible(isLoggedIn: true, hasActiveSubscription: true, tier: .plus, flagEnabled: false))
    }

    func testDefaultPollingPolicyMatchesSharedPrototype() {
        XCTAssertEqual(TranscriptManager.defaultPollingInterval, 15)
        XCTAssertEqual(TranscriptManager.defaultPollingTimeout, 5 * 60)
    }

    func testPollingBudgetAccumulatesForegroundTimeAcrossResumes() {
        var budget = TranscriptForegroundPollingBudget(duration: 5 * 60)
        let firstStart = Date(timeIntervalSinceReferenceDate: 0)
        budget.consume(from: firstStart, to: firstStart.addingTimeInterval(2 * 60))
        XCTAssertEqual(budget.remaining, 3 * 60)

        let resumedStart = Date(timeIntervalSinceReferenceDate: 10 * 60)
        budget.consume(from: resumedStart, to: resumedStart.addingTimeInterval(3 * 60))
        XCTAssertEqual(budget.remaining, 0)
    }

    func testAcceptedOnDemandRequestIsSentOnlyOncePerManager() async throws {
        let response = OnDemandTranscriptResponse(outcome: .queued, reason: .unspecified, enablement: .enabled, newlyQueuedCount: 3)
        let service = MockOnDemandService(result: .success(response))
        let manager = TranscriptManager(
            episodeUUID: "episode-id",
            podcastUUID: "podcast-id",
            showCoordinator: MissingMockShowCoordinator(),
            onDemandService: service,
            isEligibleForOnDemand: { true }
        )

        _ = try await manager.requestOnDemandTranscript()
        var lifecycle = TranscriptLoadingLifecycle()
        lifecycle.started()
        lifecycle.enteredBackground()
        XCTAssertTrue(lifecycle.shouldResumeOnForeground(isVisible: true))
        _ = try await manager.requestOnDemandTranscript()

        let requestCount = await service.requestCount
        XCTAssertEqual(requestCount, 1)
    }

    func testTranscriptLoadingDoesNotResumeAfterLeavingScreenInBackground() {
        var lifecycle = TranscriptLoadingLifecycle()
        lifecycle.started()
        lifecycle.enteredBackground()
        lifecycle.leftScreen()

        XCTAssertFalse(lifecycle.shouldResumeOnForeground(isVisible: true))
        XCTAssertFalse(lifecycle.isPending)
    }

    func testTranscriptLoadingDoesNotResumeWhenScreenIsNoLongerVisible() {
        var lifecycle = TranscriptLoadingLifecycle()
        lifecycle.started()
        lifecycle.enteredBackground()

        XCTAssertFalse(lifecycle.shouldResumeOnForeground(isVisible: false))
        XCTAssertFalse(lifecycle.isPending)
    }

    func testRejectedOnDemandRequestDoesNotStartGeneration() async {
        let response = OnDemandTranscriptResponse(
            outcome: .notEligible,
            reason: .podcastDisallowed,
            enablement: .notEnabled,
            newlyQueuedCount: 0
        )
        let manager = TranscriptManager(
            episodeUUID: "episode-id",
            podcastUUID: "podcast-id",
            showCoordinator: MissingMockShowCoordinator(),
            onDemandService: MockOnDemandService(result: .success(response)),
            isEligibleForOnDemand: { true }
        )

        do {
            _ = try await manager.requestOnDemandTranscript()
            XCTFail("Expected request rejection")
        } catch TranscriptGenerationError.rejected(let reason) {
            XCTAssertEqual(reason, .podcastDisallowed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOfflineOnDemandRequestIsTransient() async {
        let manager = TranscriptManager(
            episodeUUID: "episode-id",
            podcastUUID: "podcast-id",
            showCoordinator: MissingMockShowCoordinator(),
            onDemandService: MockOnDemandService(result: .failure(URLError(.notConnectedToInternet))),
            isEligibleForOnDemand: { true }
        )

        do {
            _ = try await manager.requestOnDemandTranscript()
            XCTFail("Expected transient error")
        } catch TranscriptGenerationError.transient {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPollingCompletesWhenGeneratedTranscriptAppears() async throws {
        let manager = TranscriptManager(
            episodeUUID: "episode-id",
            podcastUUID: "podcast-id",
            showCoordinator: GeneratedMockShowCoordinator(),
            pollingInterval: 0.001,
            pollingTimeout: 1
        )

        try await manager.waitForGeneratedTranscript()

        XCTAssertTrue(manager.hasGeneratedTranscripts)
        XCTAssertTrue(manager.isDisplayingGeneratedTranscript)
    }

    func testPollingTimesOutWhenTranscriptRemainsMissing() async {
        let manager = TranscriptManager(
            episodeUUID: "episode-id",
            podcastUUID: "podcast-id",
            showCoordinator: MissingMockShowCoordinator(),
            pollingInterval: 0.001,
            pollingTimeout: 0.01
        )

        do {
            try await manager.waitForGeneratedTranscript()
            XCTFail("Expected timeout")
        } catch TranscriptGenerationError.delayed {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
