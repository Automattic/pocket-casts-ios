import Foundation
import SwiftSubtitles
import PocketCastsDataModel

class TranscriptManager {

    typealias Transcript = Episode.Metadata.Transcript

    enum TranscriptFormat: String {
        case srt = "application/srt"
        case vtt = "text/vtt"

        var fileExtension: String {
            switch self {
            case .srt:
                return "srt"
            case .vtt:
                return "vtt"
            }
        }
    }

    // Transcript formats we support in order of priority of use
    static let supportedFormats: [TranscriptFormat] = [.srt, .vtt]

    enum TranscriptError: Error {
        case notAvailable
        case failedToLoad
        case notSupported(format: String)

        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "Transcript not available"
            case .failedToLoad:
                return "Transcript failed to load"
            case .notSupported(let format):
                return "Transcript format not supported: \(format)"
            }
        }
    }

    let playbackManager: PlaybackManager

    init(playbackManager: PlaybackManager) {
        self.playbackManager  = playbackManager
    }

    private func bestTranscript(from available: [Transcript]) -> Transcript? {
        for format in Self.supportedFormats {
            if let transcript = available.first(where: { $0.type == format.rawValue}) {
                return transcript
            }
        }
        return available.first
    }

    public func loadTranscript() async throws -> String {
        guard
            let episode = self.playbackManager.currentEpisode(), let podcast = self.playbackManager.currentPodcast,
            let transcripts = try? await ShowInfoCoordinator.shared.loadTranscripts(podcastUuid: podcast.uuid, episodeUuid: episode.uuid),
            let transcript = bestTranscript(from: transcripts) else {
            throw TranscriptError.notAvailable
        }

        guard let transcriptFormat = transcript.transcriptFormat else {
            throw TranscriptError.notSupported(format: transcript.type)
        }

        guard
            let transcriptURL = URL(string: transcript.url),
            let transcriptText = try? String(contentsOf: transcriptURL)
        else {
            throw TranscriptError.failedToLoad
        }

        let subtitle = try Subtitles(content: transcriptText, expectedExtension: transcriptFormat.fileExtension)
        return String(subtitle.text.joined(separator: "\n"))
    }
}

extension Episode.Metadata.Transcript {

    var transcriptFormat: TranscriptManager.TranscriptFormat? {
        return TranscriptManager.TranscriptFormat(rawValue: self.type)
    }
}
