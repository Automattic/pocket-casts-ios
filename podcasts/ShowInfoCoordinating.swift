import Foundation
import PocketCastsDataModel
import PocketCastsServer

protocol ShowInfoCoordinating {
    init(
        dataRetriever: ShowInfoDataRetriever,
        dataManager: DataManager
    )
    
    func loadShowNotes(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String
    
    func loadEpisodeArtworkUrl(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String?
}
