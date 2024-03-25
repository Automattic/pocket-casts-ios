import Foundation
import PocketCastsDataModel
import PocketCastsServer

struct PodcastIndexEvelope: Decodable {
    let chapters: [PodcastIndexChapter]
}

struct PodcastIndexChapter: Decodable {
    let title: String?
    let number: Int?
    let endTime: TimeInterval?
    let startTime: TimeInterval
}

actor ShowInfoCoordinator: ShowInfoCoordinating {
    static let shared = ShowInfoCoordinator()

    private let dataRetriever: ShowInfoDataRetriever
    private let podcastIndexChapterRetriever: PodcastIndexChapterDataRetriever
    private let dataManager: DataManager

    private var requestingShowInfo: [String: Task<Episode.Metadata?, Error>] = [:]

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
            let chaptersData = try? await podcastIndexChapterRetriever.loadChapters(pocastIndexChapterUrl) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let chapters = try? decoder.decode(PodcastIndexEvelope.self, from: chaptersData)
            return (nil, chapters?.chapters)
        }

        return (metadata?.chapters, nil)
    }

    @discardableResult
    func loadShowInfo(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> Episode.Metadata? {
        if let metadata = await dataManager.findEpisodeMetadata(uuid: episodeUuid) {
            return metadata
        }

        return try await requestShowInfo(podcastUuid: podcastUuid, episodeUuid: episodeUuid)
    }

    @discardableResult
    func requestShowInfo(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> Episode.Metadata? {
        if let task = requestingShowInfo[podcastUuid] {
            return try await task.value
        }

        let task = Task<Episode.Metadata?, Error> { [unowned self] in
            let data = try await dataRetriever.loadShowInfoData(for: podcastUuid)
            await dataManager.storeShowInfo(data: data)
            let episode = await dataManager.findEpisodeMetadata(uuid: episodeUuid)
            requestingShowInfo[podcastUuid] = nil
            return episode
        }

        requestingShowInfo[podcastUuid] = task

        return try await task.value
    }
}
