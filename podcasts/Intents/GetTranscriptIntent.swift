import AppIntents
import PocketCastsDataModel

enum GetTranscriptError: Error, CustomLocalizedStringResourceConvertible {
    case episodeNotFound
    case transcriptNotAvailable
    case transcriptFailedToLoad
    case transcriptEmpty

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .episodeNotFound:
            "Episode not found"
        case .transcriptNotAvailable:
            "Transcript not available for this episode"
        case .transcriptFailedToLoad:
            "Failed to load transcript"
        case .transcriptEmpty:
            "Transcript is empty"
        }
    }
}

struct GetTranscriptIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Transcript"
    static var description = IntentDescription("Get the transcript for an episode")

    @Parameter(title: "Episode")
    var episode: EpisodeSearchEntity
    
    @Parameter(title: "Timestamp (seconds)", description: "Optional timestamp to get transcript from a specific time")
    var timestamp: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Get transcript for \(\.$episode)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let transcriptManager = TranscriptManager(
            episodeUUID: episode.episodeUuid,
            podcastUUID: episode.podcastUuid
        )

        do {
            let transcriptModel = try await transcriptManager.loadTranscript()

            // Extract plain text from attributed string
            let transcriptText = transcriptModel.attributedText.string

            guard !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw GetTranscriptError.transcriptEmpty
            }

            return .result(value: transcriptText))

        } catch TranscriptError.notAvailable {
            throw GetTranscriptError.transcriptNotAvailable
        } catch TranscriptError.failedToLoad, TranscriptError.failedToParse {
            throw GetTranscriptError.transcriptFailedToLoad
        } catch TranscriptError.empty {
            throw GetTranscriptError.transcriptEmpty
        } catch {
            throw GetTranscriptError.transcriptFailedToLoad
        }
    }
}
