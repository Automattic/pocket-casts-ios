import Foundation
import PocketCastsDataModel
import PocketCastsServer

protocol ShowInfoCoordinating {
    typealias EpisodeTranscriptData = (transcripts: [Episode.Metadata.Transcript], hasGeneratedTranscripts: Bool, isDisplayingGeneratedTranscript: Bool)

    func loadShowNotes(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String

    func loadEpisodeArtworkUrl(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> URL?

    func loadChapters(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> ([Episode.Metadata.EpisodeChapter]?, [PodcastIndexChapter]?, [GeneratedChapter]?)

    func loadTranscriptsMetadata(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> EpisodeTranscriptData

    func refreshTranscriptsMetadata(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> EpisodeTranscriptData
}

extension ShowInfoCoordinating {
    func refreshTranscriptsMetadata(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> EpisodeTranscriptData {
        try await loadTranscriptsMetadata(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
    }
}
