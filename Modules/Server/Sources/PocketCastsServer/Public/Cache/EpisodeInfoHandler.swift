import Foundation

/// Request information about an episode using the show notes endpoint
public class EpisodeInfoHandler {
    private let showNotesUrlCache: URLCache

    private var requestingNotes: [String: Bool] = [:]

    private var showNotesCompletionBlocks: [String: [(ShowNotesPodcast?) -> Void]] = [:]
    private var showNotesCachedCompletionBlocks: [String: [(ShowNotesPodcast?) -> Void]] = [:]

    let lock = NSLock()

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

    public func loadShowNotes(podcastUuid: String, episodeUuid: String, cached: ((String) -> Void)? = nil, completion: ((String?) -> Void)?) {
        var cachedNotes = ""
        var didSendCachedNotes = false

        requestShowNotes(for: podcastUuid, cached: { showNotes in
            if let notes = showNotes?.episode(with: episodeUuid)?.showNotes {
                cached?(notes)
                cachedNotes = notes
                didSendCachedNotes = true
            }
        }, completion: { showNotes in
            if let episodeNotes = showNotes?.episodes.first(where: { $0.uuid == episodeUuid })?.showNotes {
                if didSendCachedNotes, episodeNotes == cachedNotes {
                    return
                }

                completion?(episodeNotes)
            } else if !didSendCachedNotes {
                completion?(CacheServerHandler.noShowNotesMessage)
            }
        })
    }

    /// Multiple calls can be made to this method and we'll ensure that only
    /// one request per time is made to the show notes endpoint — avoiding
    /// multiple calls.
    /// - Parameters:
    ///   - for: a podcast UUID
    ///   - cached: a closure that receive a cached notes information
    ///   - completion: a closure that *might* receive a cached or update notes information
    private func requestShowNotes(for podcastUuid: String, cached: @escaping (ShowNotesPodcast?) -> Void, completion: @escaping (ShowNotesPodcast?) -> Void) {
        lock.lock()
        if showNotesCachedCompletionBlocks[podcastUuid] == nil {
            showNotesCachedCompletionBlocks[podcastUuid] = []
        }

        if showNotesCompletionBlocks[podcastUuid] == nil {
            showNotesCompletionBlocks[podcastUuid] = []
        }

        showNotesCachedCompletionBlocks[podcastUuid]?.append(cached)
        showNotesCompletionBlocks[podcastUuid]?.append(completion)

        guard requestingNotes[podcastUuid] == nil || requestingNotes[podcastUuid] == false else {
            lock.unlock()
            return
        }

        requestingNotes[podcastUuid] = true

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let url = ServerHelper.asUrl(ServerConstants.Urls.cache() + "mobile/show_notes/full/\(podcastUuid)")
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        // Check for any cached version and if there's any call the cached completion blocks
        if let cachedResponse = showNotesUrlCache.cachedResponse(for: request),
           let showNotes = try? decoder.decode(ShowNotes.self, from: cachedResponse.data) {

            showNotesCachedCompletionBlocks[podcastUuid]?.forEach { $0(showNotes.podcast) }
            showNotesCachedCompletionBlocks[podcastUuid] = []
            requestingNotes[podcastUuid] = false
        }
        lock.unlock()

        // Call the endpoint to request for a more up-to-date notes information
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            if let data = data,
               let response = response,
               let showNotes = try? decoder.decode(ShowNotes.self, from: data) {
                let responseToCache = CachedURLResponse(response: response, data: data)
                self?.showNotesUrlCache.storeCachedResponse(responseToCache, for: request)

                self?.lock.lock()
                self?.showNotesCompletionBlocks[podcastUuid]?.forEach { $0(showNotes.podcast) }
                self?.showNotesCompletionBlocks[podcastUuid] = []
                self?.lock.unlock()
            } else {
                self?.lock.lock()
                self?.showNotesCompletionBlocks[podcastUuid]?.forEach { $0(nil) }
                self?.showNotesCompletionBlocks[podcastUuid] = []
                self?.lock.unlock()
            }

            self?.requestingNotes[podcastUuid] = false
        }.resume()
    }

    public func loadEpisodeArtworkUrl(podcastUuid: String, episodeUuid: String, completion: ((String?) -> Void)?) {
        var retrievedImage = ""
        let completionBlock: (ShowNotesPodcast?) -> Void = { episodeNotes in
            guard let image = episodeNotes?.episodes.first(where: { $0.uuid == episodeUuid })?.image,
                  image != retrievedImage else {
                return
            }

            retrievedImage = image
            completion?(image)
        }

        requestShowNotes(for: podcastUuid, cached: completionBlock, completion: completionBlock)
    }
}
