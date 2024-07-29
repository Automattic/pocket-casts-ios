import XCTest
@testable import PocketCastsDataModel
@testable import podcasts

final class TranscriptManagerTests: XCTestCase {

    class MockShowCoordinator: ShowInfoCoordinating {
        func loadShowNotes(podcastUuid: String, episodeUuid: String) async throws -> String {
            return ""
        }

        func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String) async throws -> String? {
            return nil
        }

        func loadChapters(podcastUuid: String, episodeUuid: String) async throws -> ([Episode.Metadata.EpisodeChapter]?, [podcasts.PodcastIndexChapter]?) {
            return (nil, nil)
        }

        func loadTranscripts(podcastUuid: String, episodeUuid: String) async throws -> [Episode.Metadata.Transcript] {
            guard let transcriptURL = Bundle(for: Self.self).url(forResource: "sample", withExtension: "vtt") else {
                return []
            }
            let transcript = Episode.Metadata.Transcript(url: transcriptURL.absoluteString, type: "text/vtt", language: nil)
            return [transcript]
        }

    }

    func testLoadingTranscript() async throws {
        let mockShowCoordinator = MockShowCoordinator()
        let manager = TranscriptManager(episodeUUID: UUID().uuidString, podcastUUID: UUID().uuidString, showCoordinator: mockShowCoordinator)

        let model = try await manager.loadTranscript()

        XCTAssertFalse(model.cues.isEmpty)
        XCTAssertEqual(model.cues.count, 13)
    }

}
