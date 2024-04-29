import Foundation
import PocketCastsDataModel
import PocketCastsServer

actor ShowInfoCoordinator: ShowInfoCoordinating {
    static let shared = ShowInfoCoordinator()

    private let dataRetriever: ShowInfoDataRetriever
    private let podcastIndexChapterRetriever: PodcastIndexChapterDataRetriever
    private let dataManager: DataManager

    private var requestingShowInfo: [String: Task<Episode.Metadata?, Error>] = [:]
    private var requestingRawMetadata: [String: Task<String?, Error>] = [:]

    init(
        dataRetriever: ShowInfoDataRetriever = ShowInfoDataRetriever(),
        podcastIndexChapterRetriever: PodcastIndexChapterDataRetriever = PodcastIndexChapterDataRetriever(),
        dataManager: DataManager = .sharedManager
    ) {
        self.dataRetriever = dataRetriever
        self.podcastIndexChapterRetriever = podcastIndexChapterRetriever
        self.dataManager = dataManager
    }

    func loadShowNotes(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String {
        let metadata = try await loadShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        return metadata?.showNotes ?? CacheServerHandler.noShowNotesMessage
    }

    func loadEpisodeArtworkUrl(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        let metadata = try await loadShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
        return metadata?.image
    }

    public func loadChapters(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> ([Episode.Metadata.EpisodeChapter]?, [PodcastIndexChapter]?) {
        let metadata = try await loadShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)

        if let pocastIndexChapterUrl = metadata?.chaptersUrl,
            let chapters = try? await podcastIndexChapterRetriever.loadChapters(pocastIndexChapterUrl) {
            return (nil, chapters.chapters)
        }

        return (metadata?.chapters, nil)
    }

    @discardableResult
    func loadShowInfo(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> Episode.Metadata? {
        if let metadata = try? await dataManager.findEpisodeMetadata(uuid: episodeUuid) {
            return metadata
        }

        return try await requestShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
    }

    func loadRawMetadata(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        if let metadata = try? await dataManager.findRawEpisodeMetadata(uuid: episodeUuid) {
            return metadata
        }

        return try await requestRawMetadata(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
    }

    @discardableResult
    func requestRawMetadata(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        if let task = requestingRawMetadata[episodeUuid] {
            return try await task.value
        }

        let task = Task<String?, Error> { [unowned self] in
            do {
                let data = try await dataRetriever.loadShowInfoData(for: podcastUuid)
                try await dataManager.storeMetadata(episodeUuid: episodeUuid, data: data)
                let episode = try await dataManager.findRawEpisodeMetadata(uuid: episodeUuid)
                requestingRawMetadata[episodeUuid] = nil
                return episode
            } catch {
                requestingRawMetadata[episodeUuid] = nil
                throw error
            }
        }

        requestingRawMetadata[episodeUuid] = task

        return try await task.value
    }

    @discardableResult
    func requestShowInfo(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> Episode.Metadata? {
        if let task = requestingShowInfo[episodeUuid] {
            return try await task.value
        }

        let task = Task<Episode.Metadata?, Error> { [unowned self] in
            do {
                let data = try await dataRetriever.loadShowInfoData(for: podcastUuid)
                try await dataManager.storeMetadata(episodeUuid: episodeUuid, data: data)
                let episode = try await dataManager.findEpisodeMetadata(uuid: episodeUuid)
                requestingShowInfo[episodeUuid] = nil
                return episode
            } catch {
                requestingShowInfo[episodeUuid] = nil
                throw error
            }
        }

        requestingShowInfo[episodeUuid] = task

        return try await task.value
    }
}

extension Episode {
    func loadMetadata() async -> Metadata? {
        if let metadata {
            return metadata
        }

        rawMetadata = try? await ShowInfoCoordinator.shared.loadRawMetadata(podcastUuid: parentIdentifier(), episodeUuid: uuid)
        return metadata
    }
}
