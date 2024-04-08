import Foundation
import PocketCastsDataModel
import PocketCastsServer

protocol ShowInfoCoordinating {
    func loadShowNotes(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String

    func loadEpisodeArtworkUrl(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String?

    func loadChapters(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> ([Episode.Metadata.EpisodeChapter]?, [PodcastIndexChapter]?)
}
