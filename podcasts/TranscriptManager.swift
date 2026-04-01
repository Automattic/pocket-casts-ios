import Foundation
import PocketCastsDataModel
import Sentry

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

    private(set) var hasGeneratedTranscripts: Bool = false

    init(episodeUUID: String, podcastUUID: String, showCoordinator: ShowInfoCoordinating = ShowInfoCoordinator.shared) {
        self.episodeUUID = episodeUUID
        self.podcastUUID = podcastUUID
        self.showCoordinator = showCoordinator
    }

    public func loadTranscript() async throws -> TranscriptModel {
        // Check for a bundled VTT transcript (used for fingerprint testing)
        if let bundledModel = loadBundledTranscript() {
            return bundledModel
        }

        guard
            let metadata = try? await showCoordinator.loadTranscriptsMetadata(podcastUuid: podcastUUID, episodeUuid: episodeUUID),
            !metadata.transcripts.isEmpty else {
            throw TranscriptError.notAvailable
        }
        var transcriptsAvailable = metadata.transcripts
        hasGeneratedTranscripts = metadata.hasGeneratedTranscripts
        while let transcript = TranscriptFormat.bestTranscript(from: transcriptsAvailable) {
            do {
                let model = try await loadTranscript(transcript)
                return model
            } catch TranscriptError.empty, TranscriptError.failedToParse {
                transcriptsAvailable.removeAll { other in
                    other.transcriptFormat == transcript.transcriptFormat
                }
            } catch {
                throw error
            }
        }
        throw TranscriptError.failedToLoad
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

        let crumb = Breadcrumb()
        crumb.level = SentryLevel.info
        crumb.category = "transcript"
        crumb.message = "Transcript file \(transcriptURL)"
        SentrySDK.addBreadcrumb(crumb)

        guard let model = TranscriptModel.makeModel(from: transcriptText, format: transcriptFormat) else {
            throw TranscriptError.failedToParse
        }

        if model.isEmtpy {
            throw TranscriptError.empty
        }

        return model
    }

    private func loadBundledTranscript() -> TranscriptModel? {
        guard let url = Bundle.main.url(forResource: episodeUUID, withExtension: "vtt"),
              let vttText = try? String(contentsOf: url, encoding: .utf8),
              let model = TranscriptModel.makeModel(from: vttText, format: .vtt) else {
            return nil
        }
        return model
    }

    private lazy var dataRetriever: TranscriptsDataRetriever = {
        return TranscriptsDataRetriever()
    }()
}
