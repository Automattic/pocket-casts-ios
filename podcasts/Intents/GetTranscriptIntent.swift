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

    @Parameter(title: "Range (seconds)", description: "Number of seconds of transcript to fetch (default: all remaining)")
    var range: Double?

    @Parameter(title: "Offset (seconds)", description: "Seconds to shift the timestamp (negative values go back in time)")
    var offset: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Get transcript for \(\.$episode)") {
            \.$timestamp
            \.$range
            \.$offset
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let transcriptManager = TranscriptManager(
            episodeUUID: episode.episodeUuid,
            podcastUUID: episode.podcastUuid
        )

        do {
            let transcriptModel = try await transcriptManager.loadTranscript()

            // Filter transcript based on timestamp, offset, and range if provided
            let transcriptText: String

            // Determine the starting timestamp
            let startingTimestamp: Double?
            if let timestamp = timestamp {
                startingTimestamp = timestamp
            } else if PlaybackManager.shared.isNowPlayingEpisode(episodeUuid: episode.episodeUuid) {
                // Use current playback time if this episode is currently playing
                startingTimestamp = PlaybackManager.shared.currentTime()
            } else {
                startingTimestamp = nil
            }

            if let timestamp = startingTimestamp {
                // Apply offset to the timestamp (negative values go back in time)
                let adjustedTimestamp = max(0, timestamp + (offset ?? 0))
                let endTime = range.map { adjustedTimestamp + $0 }

                // Find cues within the specified time range
                let filteredCues = transcriptModel.cues.filter { cue in
                    if let endTime = endTime {
                        // Include cues that start within the range or overlap with the range
                        return cue.startTime >= adjustedTimestamp && cue.startTime < endTime
                    } else {
                        // No end time specified, include all cues from adjusted timestamp onwards
                        return cue.startTime >= adjustedTimestamp
                    }
                }

                if filteredCues.isEmpty {
                    // If no cues found in the specified range, return empty
                    throw GetTranscriptError.transcriptEmpty
                }

                // Extract text from filtered cues
                let filteredAttributedText = NSMutableAttributedString()
                for cue in filteredCues {
                    let cueText = transcriptModel.attributedText.attributedSubstring(from: cue.characterRange)
                    filteredAttributedText.append(cueText)
                }
                transcriptText = filteredAttributedText.string
            } else {
                // Extract plain text from attributed string
                transcriptText = transcriptModel.attributedText.string
            }

            guard !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw GetTranscriptError.transcriptEmpty
            }

            return .result(value: transcriptText)

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
