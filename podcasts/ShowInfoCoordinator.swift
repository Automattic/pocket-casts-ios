import Foundation
import PocketCastsDataModel
import PocketCastsServer


struct ShowInfo: Decodable {
    let podcast: ShowInfoPodcast
}

struct ShowInfoPodcast: Decodable {
    let episodes: [ShowInfoEpisode]
    
    func episode(with uuid: String) -> ShowInfoEpisode? {
        episodes.first(where: { $0.uuid == uuid })
    }
}

struct ShowInfoEpisode: Decodable {
    let uuid: String
    let showNotes: String
    let image: String?

    /// Podlove chapters
    let chapters: [EpisodeChapter]?

    /// Podcast Index chapters
    let chaptersUrl: String?

    public struct EpisodeChapter: Decodable {
        public let startTime: TimeInterval
        public let title: String?
        public let endTime: TimeInterval?
    }
}

actor ShowInfoCoordinator: ShowInfoCoordinating {
    static let shared = ShowInfoCoordinator()

    private let dataRetriever: ShowInfoDataRetriever
    private let dataManager: DataManager

    private var requestingShowInfo: [String: Task<ShowInfo?, Error>] = [:]

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
        let info = try await retrieveShowInfo(podcastUuid: podcastUuid)
        return info?.podcast.episode(with: episodeUuid)?.showNotes ?? CacheServerHandler.noShowNotesMessage
    }

    func loadEpisodeArtworkUrl(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> String? {
        let info = try await retrieveShowInfo(podcastUuid: podcastUuid)
        return info?.podcast.episode(with: episodeUuid)?.image
    }

    public func loadChapters(
        podcastUuid: String,
        episodeUuid: String
    ) async throws -> ([ShowInfoEpisode.EpisodeChapter]?, String?) {
        let info = try await retrieveShowInfo(podcastUuid: podcastUuid)
        let episode = info?.podcast.episode(with: episodeUuid)
        return (episode?.chapters, episode?.chaptersUrl)
    }

    @discardableResult
    func retrieveShowInfo(podcastUuid: String) async throws -> ShowInfo? {
        if let task = requestingShowInfo[podcastUuid] {
            return try await task.value
        }

        let task = Task<ShowInfo?, Error> { [unowned self] in
            let data = try await dataRetriever.loadShowInfoData(for: podcastUuid)
            let info = await getShowInfo(for: data)
            requestingShowInfo[podcastUuid] = nil
            return info
        }

        requestingShowInfo[podcastUuid] = task
        
        return try await task.value
    }

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private func getShowInfo(for data: Data) async -> ShowInfo? {
        do {
            return try decoder.decode(ShowInfo.self, from: data)
        } catch {
            return nil
        }
    }
}
