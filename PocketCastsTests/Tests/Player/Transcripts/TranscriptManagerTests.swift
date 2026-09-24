import XCTest
@testable import PocketCastsDataModel
@testable import podcasts

final class TranscriptManagerTests: XCTestCase {

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

    class PlainTextMockShowCoordinator: MockShowCoordinator {
        override func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            guard let transcriptURL = Bundle(for: Self.self).url(forResource: "sample", withExtension: "txt") else {
                return (transcripts: [], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
            }
            let transcript = Episode.Metadata.Transcript(url: transcriptURL.absoluteString, type: "text/plain", language: nil)
            return (transcripts: [transcript], hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
        }
    }

    class StubbedMockShowCoordinator: MockShowCoordinator {
        let transcripts: [Episode.Metadata.Transcript]

        init(transcripts: [Episode.Metadata.Transcript]) {
            self.transcripts = transcripts
        }

        override func loadTranscriptsMetadata(podcastUuid: String, episodeUuid: String) async throws -> EpisodeTranscriptData {
            return (transcripts: transcripts, hasGeneratedTranscripts: false, isDisplayingGeneratedTranscript: false)
        }
    }

    override func tearDown() {
        TranscriptStubURLProtocol.responses = [:]
        super.tearDown()
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

    func testLoadingPlainTextTranscript() async throws {
        let manager = TranscriptManager(episodeUUID: UUID().uuidString, podcastUUID: UUID().uuidString, showCoordinator: PlainTextMockShowCoordinator())

        let model = try await manager.loadTranscript()

        XCTAssertTrue(model.attributedText.string.contains("Today I'm speaking with Daniel Kokotajlo."))
        XCTAssertTrue(model.cues.isEmpty)
    }

    func testLoadingTranscriptThrowsWhenTranscriptRequestFails() async {
        let url = URL(string: "https://example.com/\(UUID().uuidString).txt")!
        TranscriptStubURLProtocol.responses[url] = (403, TranscriptStubURLProtocol.accessDeniedBody)
        let manager = makeStubbedManager(transcripts: [Episode.Metadata.Transcript(url: url.absoluteString, type: "text/plain", language: nil)])

        do {
            let model = try await manager.loadTranscript()
            XCTFail("Expected an error, got \(model.attributedText.string)")
        } catch TranscriptError.failedToLoad {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLoadingTranscriptFallsBackWhenPreferredFormatFailsToLoad() async throws {
        let vttURL = URL(string: "https://example.com/\(UUID().uuidString).vtt")!
        let textURL = URL(string: "https://example.com/\(UUID().uuidString).txt")!
        TranscriptStubURLProtocol.responses[vttURL] = (403, TranscriptStubURLProtocol.accessDeniedBody)
        TranscriptStubURLProtocol.responses[textURL] = (200, "Fallback transcript text")
        let manager = makeStubbedManager(transcripts: [
            Episode.Metadata.Transcript(url: vttURL.absoluteString, type: "text/vtt", language: nil),
            Episode.Metadata.Transcript(url: textURL.absoluteString, type: "text/plain", language: nil)
        ])

        let model = try await manager.loadTranscript()

        XCTAssertTrue(model.attributedText.string.contains("Fallback transcript text"))
    }

    private func makeStubbedManager(transcripts: [Episode.Metadata.Transcript]) -> TranscriptManager {
        TranscriptManager(
            episodeUUID: UUID().uuidString,
            podcastUUID: UUID().uuidString,
            showCoordinator: StubbedMockShowCoordinator(transcripts: transcripts),
            dataRetriever: TranscriptsDataRetriever(urlSession: TranscriptStubURLProtocol.makeSession())
        )
    }
}
