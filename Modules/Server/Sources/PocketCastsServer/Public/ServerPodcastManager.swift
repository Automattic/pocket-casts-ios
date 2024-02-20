import Foundation
import PocketCastsDataModel

public class ServerPodcastManager: NSObject {
    private static let maxAutoDownloadSeperationTime = 12.hours

    public static let shared = ServerPodcastManager()

    lazy var isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    lazy var subscribeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    lazy var importerQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    private let urlConnection = URLConnection(handler: URLSession.shared)

    // MARK: - Podcast add functions
    
    /// This tries to add the podcast with UUID up to 3 times.
    /// If The poll mechanism is to be used in cases when the podcast was just added to server and the first call might fail because the server didn't have time to update
    /// The call will try a maximum of three time with each call having an exponetial backoff period of base 2 seconds for each try
    /// - Parameters:
    ///   - podcastUuid: the uuid of the podcast to caache
    ///   - subscribe: if we should subscribe to the podcast after adding
    ///   - tries: the number of tries already done
    ///   - completion: the code to execute on completion
    public func addFromUuidWithRetries(podcastUuid: String, subscribe: Bool, tries: UInt = 0, completion: ((Bool) -> Void)?) {
        var pollbackCounter = tries
        addFromUuid(podcastUuid: podcastUuid, subscribe: subscribe) { [weak self]success in
            if success {
                completion?(success)
                return
            }
            pollbackCounter += 1
            if pollbackCounter < 3 {
                Thread.sleep(forTimeInterval: pow(2, Double(pollbackCounter)))
                self?.addFromUuidWithRetries(podcastUuid: podcastUuid, subscribe: subscribe, tries: pollbackCounter, completion: completion)
                return
            }
            completion?(success)
        }
    }

    public func addFromUuid(podcastUuid: String, subscribe: Bool, completion: ((Bool) -> Void)?) {
        CacheServerHandler.shared.loadPodcastInfo(podcastUuid: podcastUuid) { [weak self] podcastInfo, lastModified in
            if let podcastInfo = podcastInfo {
                self?.addFromJson(podcastUuid: podcastUuid, lastModified: lastModified, podcastInfo: podcastInfo, subscribe: subscribe, completion: completion)
            } else {
                completion?(false)
            }
        }
    }

    public func addFromiTunesId(_ itunesId: Int, subscribe: Bool, completion: ((Bool, String?) -> Void)?) {
        MainServerHandler.shared.findPodcastByiTunesId(itunesId) { [weak self] podcastUuid in
            guard let uuid = podcastUuid else {
                completion?(false, nil)
                return
            }

            self?.addFromUuid(podcastUuid: uuid, subscribe: subscribe, completion: { added in
                completion?(added, uuid)
            })
        }
    }

    public func addFromJson(podcastUuid: String, lastModified: String?, podcastInfo: [String: Any], subscribe: Bool, completion: ((Bool) -> Void)?) {
        subscribeQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }

            let added = strongSelf.addPodcast(podcastInfo: podcastInfo, subscribe: subscribe, lastModified: lastModified)
            if subscribe, added { ServerConfig.shared.syncDelegate?.subscribedToPodcast() } // addFromUuid and addFromiTunesId end up here, so just need this one analytic
            completion?(added)
        }
    }

    public func addPodcastFromUpNextItem(_ upNextItem: UpNextItem, completion: ((Bool) -> Void)?) {
        if let existingPodcast = DataManager.sharedManager.findPodcast(uuid: upNextItem.podcastUuid, includeUnsubscribed: true) {
            // we have the podcast, but not the episode, so it's ok to just save it in
            addToDatabase(upNextItem: upNextItem, to: existingPodcast)
            completion?(true)

            return
        }

        // otherwise we don't have the podcast, try and get it
        addFromUuid(podcastUuid: upNextItem.podcastUuid, subscribe: false) { [weak self] added in
            if !added {
                completion?(false)
                return
            }

            guard let existingPodcast = DataManager.sharedManager.findPodcast(uuid: upNextItem.podcastUuid, includeUnsubscribed: true) else {
                completion?(false)
                return
            }

            // at this point we have the podcast, now we need the sync info for it if we're signed in
            if SyncManager.isUserLoggedIn() {
                guard let episodes = ApiServerHandler.shared.retrieveEpisodeTaskSynchronouusly(podcastUuid: upNextItem.podcastUuid) else { return }

                DataManager.sharedManager.saveBulkEpisodeSyncInfo(episodes: DataConverter.convert(syncInfoEpisodes: episodes))
            }

            self?.addToDatabase(upNextItem: upNextItem, to: existingPodcast)
            completion?(true)
        }
    }

    public func addMissingPodcast(episodeUuid: String, podcastUuid: String) {
        let url = ServerConstants.Urls.cache() + "mobile/podcast/findbyepisode/\(podcastUuid)/\(episodeUuid)"

        if let info = loadFrom(url: url), addPodcast(podcastInfo: info, subscribe: false, lastModified: nil) {
            // all good
        }
    }

    public func addMissingEpisode(episodeUuid: String, podcastUuid: String) -> Episode? {
        let url = ServerConstants.Urls.cache() + "mobile/podcast/findbyepisode/\(podcastUuid)/\(episodeUuid)"

        if let info = loadFrom(url: url) {
            return addEpisode(podcastInfo: info)
        }

        return nil
    }

    public func addMissingPodcastAndEpisode(episodeUuid: String, podcastUuid: String) {
        let url = ServerConstants.Urls.cache() + "mobile/podcast/findbyepisode/\(podcastUuid)/\(episodeUuid)"

        if let info = loadFrom(url: url) {
            // Ensure podcast is added, otherwise episode won't be
            if !PodcastExistsHelper.shared.exists(uuid: podcastUuid) {
                _ = addPodcast(podcastInfo: info, subscribe: false, lastModified: nil)
            }

            _ = addEpisode(podcastInfo: info)
        }
    }

    private func addToDatabase(upNextItem: UpNextItem, to podcast: Podcast) {
        // if we have this episode already, then we don't need to do anything here
        guard DataManager.sharedManager.findEpisode(uuid: upNextItem.episodeUuid) == nil else { return }

        let episode = Episode()
        episode.addedDate = Date()
        episode.podcastUuid = podcast.uuid
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        episode.uuid = upNextItem.episodeUuid
        episode.title = upNextItem.title
        episode.downloadUrl = upNextItem.url
        episode.publishedDate = upNextItem.published
        episode.podcast_id = podcast.id

        DataManager.sharedManager.save(episode: episode)
    }

    private func addPodcast(podcastInfo: [String: Any], subscribe: Bool, lastModified: String?) -> Bool {
        guard let podcastJson = podcastInfo["podcast"] as? [String: Any], let podcastUuid = podcastJson["uuid"] as? String else { return false }

        // check if we already have this podcast, and if we do treat it differently
        if let existingPodcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true) {
            if existingPodcast.isSubscribed(), subscribe { return true }

            if !existingPodcast.isSubscribed(), subscribe {
                // we have this podcast, just in a non-subscribed state, so subscribe to it
                existingPodcast.subscribed = 1
                existingPodcast.syncStatus = SyncStatus.notSynced.rawValue
            }

            DataManager.sharedManager.save(podcast: existingPodcast)
            updateLatestEpisodeInfo(podcast: existingPodcast, setDefaults: true)

            ServerConfig.shared.syncDelegate?.podcastAdded(podcastUuid: existingPodcast.uuid)

            return true
        }

        let podcast = Podcast()
        podcast.uuid = podcastUuid
        podcast.subscribed = subscribe ? 1 : 0
        // if we're adding a new podcast but not subscribing don't mark it as needing to be synced
        if !subscribe {
            podcast.syncStatus = SyncStatus.synced.rawValue
        }
        podcast.addedDate = Date()
        podcast.sortOrder = highestSortOrderForHomeGrid() + 1
        podcast.autoDownloadSetting = AutoDownloadSetting.off.rawValue
        podcast.lastUpdatedAt = lastModified
        if let title = podcastJson["title"] as? String {
            podcast.title = title
        }
        if let author = podcastJson["author"] as? String {
            podcast.author = author
        }
        if let url = podcastJson["url"] as? String {
            podcast.podcastUrl = url
        }
        if let description = podcastJson["description"] as? String {
            podcast.podcastDescription = description
        }
        if let category = podcastJson["category"] as? String {
            podcast.podcastCategory = category
        }
        if let showType = podcastJson["show_type"] as? String {
            podcast.showType = showType
        }
        if let estimatedNextEpisode = podcastInfo["estimated_next_episode_at"] as? String {
            podcast.estimatedNextEpisode = isoFormatter.date(from: estimatedNextEpisode)
        }
        if let frequency = podcastInfo["episode_frequency"] as? String {
            podcast.episodeFrequency = frequency
        }
        if let paid = podcastJson["paid"] as? Int {
            podcast.isPaid = paid > 0
        }
        if let licensing = podcastJson["licensing"] as? Int {
            podcast.licensing = Int32(licensing)
        }
        if let refreshAvailable = podcastInfo["refresh_allowed"] as? Bool {
            podcast.refreshAvailable = refreshAvailable
        }

        // we don't accept podcasts with no episodes
        guard let episodesJson = podcastJson["episodes"] as? [[String: Any]] else { return false }

        // save the podcast so that it gets and ID
        DataManager.sharedManager.save(podcast: podcast)

        var episodes = [Episode]()
        for episodeJson in episodesJson {
            let episode = Episode()
            episode.addedDate = Date()
            episode.podcast_id = podcast.id
            episode.podcastUuid = podcast.uuid
            episode.playingStatus = PlayingStatus.notPlayed.rawValue
            episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
            if let uuid = episodeJson["uuid"] as? String {
                episode.uuid = uuid
            }
            if let title = episodeJson["title"] as? String {
                episode.title = title
            }
            if let url = episodeJson["url"] as? String {
                episode.downloadUrl = url
            }
            if let fileType = episodeJson["file_type"] as? String {
                episode.fileType = fileType
            }
            if let fileSize = episodeJson["file_size"] as? Int64 {
                episode.sizeInBytes = fileSize
            }
            if let duration = episodeJson["duration"] as? Double {
                episode.duration = duration
            }
            if let publishedStr = episodeJson["published"] as? String {
                episode.publishedDate = isoFormatter.date(from: publishedStr)
            }
            if let number = episodeJson["number"] as? Int64 {
                episode.episodeNumber = number
            }
            if let season = episodeJson["season"] as? Int64 {
                episode.seasonNumber = season
            }
            if let type = episodeJson["type"] as? String {
                episode.episodeType = type
            }

            episodes.append(episode)
        }
        DataManager.sharedManager.bulkSave(episodes: episodes)

        updateLatestEpisodeInfo(podcast: podcast, setDefaults: subscribe)

        if subscribe { ServerConfig.shared.syncDelegate?.podcastAdded(podcastUuid: podcast.uuid) }

        return true
    }

    private func addEpisode(podcastInfo: [String: Any]) -> Episode? {
        guard let podcastJson = podcastInfo["podcast"] as? [String: Any],
              let podcastUuid = podcastJson["uuid"] as? String,
              let episodesJson = podcastJson["episodes"] as? [[String: Any]],
              let podcast = DataManager.sharedManager.findPodcast(uuid: podcastUuid, includeUnsubscribed: true),
              let firstEpisode = episodesJson.first,
              let uuid = firstEpisode["uuid"] as? String else { return nil }

        if let episode = DataManager.sharedManager.findEpisode(uuid: uuid) {
            return episode // we already have this episode
        }

        let episode = Episode()
        episode.addedDate = Date()
        episode.podcast_id = podcast.id
        episode.podcastUuid = podcast.uuid
        episode.playingStatus = PlayingStatus.notPlayed.rawValue
        episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
        episode.uuid = uuid
        if let title = firstEpisode["title"] as? String {
            episode.title = title
        }
        if let url = firstEpisode["url"] as? String {
            episode.downloadUrl = url
        }
        if let fileType = firstEpisode["file_type"] as? String {
            episode.fileType = fileType
        }
        if let fileSize = firstEpisode["file_size"] as? Int64 {
            episode.sizeInBytes = fileSize
        }
        if let duration = firstEpisode["duration"] as? Double {
            episode.duration = duration
        }
        if let publishedStr = firstEpisode["published"] as? String {
            episode.publishedDate = isoFormatter.date(from: publishedStr)
        }
        if let number = firstEpisode["number"] as? Int64 {
            episode.episodeNumber = number
        }
        if let season = firstEpisode["season"] as? Int64 {
            episode.seasonNumber = season
        }
        if let type = firstEpisode["type"] as? String {
            episode.episodeType = type
        }

        DataManager.sharedManager.save(episode: episode)

        return episode
    }

    private func loadFrom(url: String) -> [String: Any]? {
        let url = ServerHelper.asUrl(url)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: ServerConstants.HttpHeaders.accept)
        request.setValue("application/json; charset=UTF8", forHTTPHeaderField: ServerConstants.HttpHeaders.contentType)
        do {
            let (responseData, response) = try urlConnection.sendSynchronousRequest(with: request)
            guard let data = responseData else { return nil }

            if let response = response as? HTTPURLResponse, response.statusCode == ServerConstants.HttpConstants.notModified {
                return nil
            }
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return jsonResponse
            }
        } catch {
            print("Failed to get from server \(error.localizedDescription)")
        }

        return nil
    }

    public func highestSortOrderForHomeGrid() -> Int32 {
        homeGridSortOrder(highest: true)
    }

    public func lowestSortOrderForHomeGrid() -> Int32 {
        homeGridSortOrder(highest: false)
    }

    public func highestSortOrderForFolder(_ folder: Folder) -> Int32 {
        let folderPodcasts = DataManager.sharedManager.allPodcastsInFolder(folder: folder)
        var highest: Int32 = 1

        for podcast in folderPodcasts {
            if podcast.sortOrder > highest { highest = podcast.sortOrder }
        }

        return highest
    }

    private func homeGridSortOrder(highest: Bool) -> Int32 {
        let gridPodcasts = DataManager.sharedManager.allPodcasts(includeUnsubscribed: false).filter { $0.folderUuid == nil }
        let allFolders = DataManager.sharedManager.allFolders()
        var value: Int32 = highest ? 1 : 0

        for podcast in gridPodcasts {
            if highest, podcast.sortOrder > value { value = podcast.sortOrder }
            else if !highest, podcast.sortOrder < value { value = podcast.sortOrder }
        }

        for folder in allFolders {
            if highest, folder.sortOrder > value { value = folder.sortOrder }
            else if !highest, folder.sortOrder < value { value = folder.sortOrder }
        }

        return value
    }
}
