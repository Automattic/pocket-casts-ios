import Foundation
import PocketCastsDataModel
import PocketCastsServer

/// Loads an episode's HTML show notes for the TV app.
///
/// Mirrors the relevant slice of the iOS `ShowInfoCoordinator`, but only pulls
/// the show-notes-shaped data. Uses `ShowInfoDataRetriever` (shared via
/// `PocketCastsServer`) so cache + network behavior matches iOS, then decodes
/// the per-episode JSON into `Episode.Metadata` and extracts `showNotes`.
actor ShowNotesLoader {
    static let shared = ShowNotesLoader()

    private let dataRetriever: ShowInfoDataRetriever

    init(dataRetriever: ShowInfoDataRetriever = ShowInfoDataRetriever()) {
        self.dataRetriever = dataRetriever
    }

    func loadShowNotes(podcastUuid: String, episodeUuid: String) async -> String {
        guard let json = try? await dataRetriever.loadEpisodeDataFromCache(for: podcastUuid, episodeUuid: episodeUuid),
              let data = json.data(using: .utf8) else {
            return CacheServerHandler.noShowNotesMessage
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let metadata = try? decoder.decode(Episode.Metadata.self, from: data)
        return metadata?.showNotes ?? CacheServerHandler.noShowNotesMessage
    }
}
