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
            return L10n.transcriptErrorNotAvailable
        case .failedToLoad:
            return L10n.transcriptErrorFailedToLoad
        case .notSupported(let format):
            return L10n.transcriptErrorNotSupported(format)
        case .failedToParse:
            return L10n.transcriptErrorFailedToParse
        case .empty:
            return L10n.transcriptErrorEmpty
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

    public func loadTranscript() async throws -> TranscriptModel {
        guard
            let transcripts = try? await showCoordinator.loadTranscriptsMetadata(podcastUuid: podcastUUID, episodeUuid: episodeUUID, cacheTranscript: false),
            let transcript = TranscriptFormat.bestTranscript(from: transcripts) else {
            throw TranscriptError.notAvailable
        }

        return try await loadTranscript(transcript)
    }

    private func loadTranscript(_ transcript: Transcript) async throws -> TranscriptModel {
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
