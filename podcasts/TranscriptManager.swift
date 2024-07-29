import Foundation
import PocketCastsDataModel

enum TranscriptError: Error {
    case notAvailable
    case failedToLoad
    case notSupported(format: String)
    case failedToParse
    case empty

    var localizedDescription: String {
        switch self {
        case .notAvailable:
            return "Transcript not available"
        case .failedToLoad:
            return "Transcript failed to load"
        case .notSupported(let format):
            return "Transcript format not supported: \(format)"
        case .failedToParse:
            return "Transcript failed to parse"
        case .empty:
            return "Transcript is empty"
        }
    }
}

class TranscriptManager {

    typealias Transcript = Episode.Metadata.Transcript

    let episodeUUID: String

    let podcastUUID: String

    let showCoordinator: ShowInfoCoordinating

    init(episodeUUID: String, podcastUUID: String, showCoordinator: ShowInfoCoordinating = ShowInfoCoordinator.shared) {
        self.episodeUUID = episodeUUID
        self.podcastUUID = podcastUUID
        self.showCoordinator = showCoordinator
    }

    private func bestTranscript(from available: [Transcript]) -> Transcript? {
        for format in TranscriptFormat.supportedFormats {
            if let transcript = available.first(where: { $0.type == format.rawValue}) {
                return transcript
            }
        }
        return available.first
    }

    public func loadTranscript() async throws -> TranscriptModel {
        guard
            let transcripts = try? await showCoordinator.loadTranscripts(podcastUuid: podcastUUID, episodeUuid: episodeUUID),
            let transcript = bestTranscript(from: transcripts) else {
            throw TranscriptError.notAvailable
        }

        guard let transcriptFormat = transcript.transcriptFormat else {
            throw TranscriptError.notSupported(format: transcript.type)
        }

        guard
            let transcriptURL = URL(string: transcript.url),
            let transcriptText = try? await dataRetriever.loadTranscript(url: transcriptURL)
        else {
            throw TranscriptError.failedToLoad
        }

        guard let model = TranscriptModel.makeModel(from: transcriptText, format: transcriptFormat) else {
            throw TranscriptError.failedToParse
        }

        if model.isEmtpy {
            throw TranscriptError.empty
        }

        return model
    }

    private lazy var dataRetriever: TranscriptsDataRetriever = {
        return TranscriptsDataRetriever()
    }()
}

extension Episode.Metadata.Transcript {

    var transcriptFormat: TranscriptFormat? {
        return TranscriptFormat(rawValue: self.type)
    }
}
