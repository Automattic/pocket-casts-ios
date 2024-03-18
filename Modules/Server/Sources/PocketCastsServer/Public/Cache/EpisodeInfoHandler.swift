import Foundation

/// Request information about an episode using the show notes endpoint
public actor EpisodeInfoHandler {
    private let showNotesUrlCache: URLCache

    private var requestingNotes: [String: Task<Data, Error>] = [:]

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init() {
        showNotesUrlCache = URLCache(memoryCapacity: 1.megabytes, diskCapacity: 10.megabytes, diskPath: "show_notes")
    }

    struct ShowNotes: Decodable {
        let podcast: ShowNotesPodcast
    }

    struct ShowNotesPodcast: Decodable {
        let episodes: [ShowNotesEpisode]

        func episode(with uuid: String) -> ShowNotesEpisode? {
            episodes.first(where: { $0.uuid == uuid })
        }
    }

    struct ShowNotesEpisode: Decodable {
        let uuid: String
        let showNotes: String
        let image: String?
    }

    public func loadShowNotes(podcastUuid: String, episodeUuid: String) async -> String {
        let showNotes = await loadShowNotes(for: podcastUuid)
        return showNotes?.podcast.episode(with: episodeUuid)?.showNotes ?? CacheServerHandler.noShowNotesMessage
    }

    public func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String) async -> String? {
        let showNotes = await loadShowNotes(for: podcastUuid)
        return showNotes?.podcast.episode(with: episodeUuid)?.image
    }
}

extension EpisodeInfoHandler {
    private func loadShowNotes(for podcastUuid: String) async -> ShowNotes? {
        do {
            let data = try await loadShowNotesData(for: podcastUuid)
            let showNotes = try decoder.decode(ShowNotes.self, from: data)
            requestingNotes[podcastUuid] = nil
            return showNotes
        } catch {
            requestingNotes[podcastUuid] = nil
            return nil
        }
    }

    private func loadShowNotesData(for podcastUuid: String) async throws -> Data {
        if let task = requestingNotes[podcastUuid] {
            return try await task.value
        }

        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if let cachedResponse = showNotesUrlCache.cachedResponse(for: request) {
            return cachedResponse.data
        }

        let task = Task<Data, Error> {
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseToCache = CachedURLResponse(response: response, data: data)
            showNotesUrlCache.storeCachedResponse(responseToCache, for: request)
            return data
        }

        requestingNotes[podcastUuid] = task

        return try await task.value
    }
}
