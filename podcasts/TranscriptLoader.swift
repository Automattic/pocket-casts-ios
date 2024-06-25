import Foundation
import SwiftSubtitles
import PocketCastsDataModel

class TranscriptLoader {

    typealias Transcript = Episode.Metadata.Transcript

    enum TranscriptError: Error {
        case notAvailable
        case failedToLoad
    }

    let playbackManager: PlaybackManager

    init(playbackManager: PlaybackManager) {
        self.playbackManager  = playbackManager
    }

    private func bestTranscript(from available: [Transcript]) -> Transcript? {
        return available.first(where: { $0.type == "application/srt"})
    }

    public func loadTranscript() async throws -> String {
        guard
            let episode = self.playbackManager.currentEpisode(), let podcast = self.playbackManager.currentPodcast,
            let transcripts = try? await ShowInfoCoordinator.shared.loadTranscripts(podcastUuid: podcast.uuid, episodeUuid: episode.uuid),
            let transcript = bestTranscript(from: transcripts) else {
            throw TranscriptError.notAvailable
        }

        guard
            let transcriptURL = URL(string: transcript.url),
            let transcriptText = try? String(contentsOf: transcriptURL)
        else {
            throw TranscriptError.failedToLoad
        }

        let subtitle = try Subtitles(content: transcriptText, expectedExtension: "srt")
        return String(subtitle.text.joined(separator: "\n"))
    }
}
