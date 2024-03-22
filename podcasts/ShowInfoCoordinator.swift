import Foundation
import PocketCastsDataModel
import PocketCastsServer

actor ShowInfoCoordinator: ShowInfoCoordinating {
    static let shared = ShowInfoCoordinator()

    private let dataRetriever: ShowInfoDataRetriever
    private let dataManager: DataManager

    private var requestingShowInfo: [String: Task<Episode?, Error>] = [:]

    init(
        dataRetriever: ShowInfoDataRetriever = ShowInfoDataRetriever(),
        dataManager: DataManager = .sharedManager
    ) {
        self.dataRetriever = dataRetriever
        self.dataManager = dataManager
    }

    func loadShowNotes(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String {
        if let showNotes = await dataManager.findEpisode(uuid: episodeUuid)?.showNotes {
            return showNotes
        }
        let episode = try await loadShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        return episode?.showNotes ?? CacheServerHandler.noShowNotesMessage
    }

    func loadEpisodeArtworkUrl(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        if let image = await dataManager.findEpisode(uuid: episodeUuid)?.image {
            return image
        }
        let episode = try await loadShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        return episode?.image
    }

    @discardableResult
    func loadShowInfo(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> Episode? {
        if let task = requestingShowInfo[podcastUuid] {
            return try await task.value
        }

        let task = Task<Episode?, Error> { [unowned self] in
            let data = try await dataRetriever.loadShowInfoData(for: podcastUuid)
            await dataManager.storeShowInfo(data: data)
            let episode = await dataManager.findEpisode(uuid: episodeUuid)
            requestingShowInfo[podcastUuid] = nil
            return episode
        }

        requestingShowInfo[podcastUuid] = task

        return try await task.value
    }
}
