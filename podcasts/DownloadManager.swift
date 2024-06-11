import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils
#if os(watchOS)
    import WatchKit
#endif
class DownloadManager: NSObject, FilePathProtocol {
    static let shared = DownloadManager(dataManager: DataManager.sharedManager)

    static let cellBackgroundSessionId = "au.com.shiftyjelly.PCManualSession"

    var progressManager = DownloadProgressManager()

    var downloadingEpisodesCache = [String: BaseEpisode]()

    var taskFailure: [String: FailureReason] = [:]

    #if os(watchOS)
        var pendingWatchBackgroundTask: WKURLSessionRefreshBackgroundTask?
    #endif

    #if !os(watchOS)
         private lazy var episodeArtwork: EpisodeArtwork = {
             EpisodeArtwork()
         }()
    #endif

    lazy var wifiOnlyBackgroundSession: URLSession = {
        var config = URLSessionConfiguration.background(withIdentifier: "au.com.shiftyjelly.PCBackgroundSession")
        config.allowsCellularAccess = false
        addStandardConfig(to: &config)

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()

    lazy var cellularBackgroundSession: URLSession = {
        var config = URLSessionConfiguration.background(withIdentifier: DownloadManager.cellBackgroundSessionId)
        config.allowsCellularAccess = true
        addStandardConfig(to: &config)

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        return session
    }()

    lazy var cellularForegroundSession: URLSession = {
        var config = URLSessionConfiguration.default

        config.allowsCellularAccess = true
        addStandardConfig(to: &config)

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        return session
    }()

    private func addStandardConfig(to config: inout URLSessionConfiguration) {
        config.httpMaximumConnectionsPerHost = Constants.Limits.maxDownloadConnectionsPerHost

        // disable cookies to prevent tracking, turns out people were actually using this the sneaky punks
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
    }

    lazy var podcastsDirectory: String = {
        let directory = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/podcasts_non_backed_up")

        return directory
    }()

    private lazy var streamingBufferDirectory: String = {
        let directory = (NSHomeDirectory() as NSString).appendingPathComponent("Documents/podcasts_buffered")

        return directory
    }()

    private var tempDownloadFolder = ""

    let dataManager: DataManager

    init(dataManager: DataManager) {
        self.dataManager = dataManager
        super.init()

        // setup the temp download folder, in caches where iOS can purge it if need be
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let cachePath = paths.first as NSString? {
            tempDownloadFolder = cachePath.appendingPathComponent("temp_download")

            let fileManager = StorageManager.self

            fileManager.createDirectory(atPath: tempDownloadFolder, withIntermediateDirectories: true)
            fileManager.createDirectory(atPath: podcastsDirectory, withIntermediateDirectories: true)
            #if !os(watchOS)
                SJCommonUtils.setDontBackupFlag(URL(fileURLWithPath: podcastsDirectory))
            #endif
            fileManager.createDirectory(atPath: streamingBufferDirectory, withIntermediateDirectories: true)
            #if !os(watchOS)
                SJCommonUtils.setDontBackupFlag(URL(fileURLWithPath: streamingBufferDirectory))
            #endif
        }
    }

    func updateProtectionPermissionsForAllExistingFiles() async {
        // Update the root permissions for the directory
        let folders = [
            tempDownloadFolder,
            podcastsDirectory,
            streamingBufferDirectory
        ]

        for folder in folders {
            let url = URL(fileURLWithPath: folder)
            StorageManager.updateFileProtectionToDefault(for: url)
        }

        // Update all the downloaded files existing protections
        guard let paths = FileManager.default.subpaths(atPath: podcastsDirectory), paths.count > 0 else {
            return
        }

        for path in paths {
            let url = URL(fileURLWithPath: podcastsDirectory + "/" + path)
            StorageManager.updateFileProtectionToDefault(for: url)
        }
    }

    func addLocalFile(url: URL, uuid: String) throws -> URL? {
        let destinationUrl = URL(fileURLWithPath: pathForUrl(fileUrl: url, uuid: uuid))
        do {
            try StorageManager.moveItem(at: url, to: destinationUrl, options: .overwriteExisting)
        } catch let error {
            let nsError = error as NSError
            switch (nsError.domain, nsError.code) {
            case (NSCocoaErrorDomain, 513):
                // No permissions to move, so we'll copy instead
                try StorageManager.copyItem(at: url, to: destinationUrl)
            default:
                throw error
            }
        }
        return destinationUrl
    }

    func queueForLaterDownload(episodeUuid: String, fireNotification: Bool, autoDownloadStatus: AutoDownloadStatus) {
        guard let episode = dataManager.findBaseEpisode(uuid: episodeUuid), !episode.downloaded(pathFinder: DownloadManager.shared) else { return }

        markUnplayedAndUnarchiveIfRequired(episode: episode, saveChanges: true)
        dataManager.saveEpisode(downloadStatus: .waitingForWifi, lastDownloadAttemptDate: Date(), autoDownloadStatus: autoDownloadStatus, episode: episode)

        FileLog.shared.addMessage("Queued episode \(episode.displayableTitle()) for later download, autoDownloadStatus: \(autoDownloadStatus)")

        if fireNotification {
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
        }
    }

    func addToQueue(episodeUuid: String, autoDownloadStatus: AutoDownloadStatus = .notSpecified) {
        addToQueue(episodeUuid: episodeUuid, fireNotification: true, autoDownloadStatus: autoDownloadStatus)
    }

    func addToQueueForStreaming(episodeUuid: String) {
        addToQueue(episodeUuid: episodeUuid, fireNotification: false, autoDownloadStatus: .playerDownloadedForStreaming)
    }

    func addToQueue(episodeUuid: String, fireNotification: Bool, autoDownloadStatus: AutoDownloadStatus) {
        // if this episode is already downloading, ignore it
        if !shouldAddDownload(episodeUuid, autoDownloadStatus: autoDownloadStatus) { return }

        guard let episode = dataManager.findBaseEpisode(uuid: episodeUuid) else { return }

        let downloadingToStream = autoDownloadStatus == AutoDownloadStatus.playerDownloadedForStreaming

        // we already have a downloaded copy of this
        if !downloadingToStream, episode.downloaded(pathFinder: self) { return }

        // we already have a buferred copy of this
        if downloadingToStream, episode.bufferedForStreaming() { return }

        // try and cache the show notes for this episode
        ShowNotesUpdater.updateShowNotesInBackground(podcastUuid: episode.parentIdentifier(), episodeUuid: episode.uuid)

        // try and cache the episode embedded artwork
        #if !os(watchOS)
        episodeArtwork.loadEmbeddedImage(asset: nil, podcastUuid: episode.parentIdentifier(), episodeUuid: episode.uuid)
        #endif

        // download requested for something we already have buferred, just move it
        if episode.bufferedForStreaming(), autoDownloadStatus != AutoDownloadStatus.playerDownloadedForStreaming {
            moveBufferedToCache(episode: episode)
        }

        let previousDownloadFailed = episode.episodeStatus == DownloadStatus.downloadFailed.rawValue
        if !downloadingToStream { episode.episodeStatus = DownloadStatus.queued.rawValue }
        episode.autoDownloadStatus = autoDownloadStatus.rawValue
        episode.downloadErrorDetails = nil
        episode.playbackErrorDetails = nil
        markUnplayedAndUnarchiveIfRequired(episode: episode, saveChanges: false)
        episode.downloadTaskId = episode.uuid
        episode.lastDownloadAttemptDate = Date()
        dataManager.save(episode: episode)

        if !downloadingToStream { progressManager.updateStatusForEpisode(episode.uuid, status: .queued) }

        if fireNotification { NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid) }

        // try to make sure the download URL is up to date. Authors can change URLs at any time, so this is handy to fix cases where they post the wrong one and update it later
        if let episode = episode as? Episode, let podcast = episode.parentPodcast(dataManager: dataManager) {
            ServerPodcastManager.shared.updatePodcastIfRequired(podcast: podcast) { [weak self] wasUpdated in
                guard let strongSelf = self, let updatedEpisode = wasUpdated ? strongSelf.dataManager.findEpisode(uuid: episodeUuid) : episode, let url = episode.downloadUrl else { return }

                Task {
                    await strongSelf.performAddToQueue(episode: updatedEpisode, url: url, previousDownloadFailed: previousDownloadFailed, fireNotification: fireNotification, autoDownloadStatus: autoDownloadStatus)
                }
            }
        } else if let episode = episode as? UserEpisode {
            ApiServerHandler.shared.uploadFilePlayRequest(episode: episode, completion: { [weak self] url in
                guard let url = url else {
                    self?.dataManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: L10n.downloadErrorTryAgain, downloadTaskId: nil, episode: episode)
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
                    return
                }

                Task { [weak self] in
                    await self?.performAddToQueue(episode: episode, url: url.absoluteString, previousDownloadFailed: previousDownloadFailed, fireNotification: fireNotification, autoDownloadStatus: autoDownloadStatus)
                }
            })
        }
    }

    func moveBufferedToCache(episode: BaseEpisode) {
        let sourceUrl = URL(fileURLWithPath: streamingBufferPathForEpisode(episode))
        let destinationUrl = URL(fileURLWithPath: pathForEpisode(episode))
        do {
            try StorageManager.moveItem(at: sourceUrl, to: destinationUrl, options: .overwriteExisting)
            let fileSize = FileManager.default.fileSize(of: destinationUrl) ?? 0
            dataManager.saveEpisode(downloadStatus: .downloaded, sizeInBytes: fileSize, downloadTaskId: nil, episode: episode)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloaded, object: episode.uuid)
        } catch {
            dataManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: L10n.downloadErrorTryAgain, downloadTaskId: nil, episode: episode)
        }

        return
    }

    func downloadParallelToStream(of episode: BaseEpisode) -> AVPlayerItem? {
        guard let playbackItem = PlaybackItem(episode: episode).createPlayerItem() else {
            return nil
        }

        guard FeatureFlag.cachePlayingEpisode.enabled,
              !episode.videoPodcast(),
              !episode.isUserEpisode,
              let urlAsset = playbackItem.asset as? AVURLAsset,
              !urlAsset.url.isFileURL // only  start download if it's a remote file that we are playing
        else {
            return playbackItem
        }
        #if !os(watchOS)
        Task {
            episode.autoDownloadStatus = AutoDownloadStatus.playerDownloadedForStreaming.rawValue
            episode.contentType = UTType.mpeg4Audio.preferredMIMEType
            let downloadTaskUUID = episode.uuid
            downloadingEpisodesCache[downloadTaskUUID] = episode
            episode.downloadTaskId = downloadTaskUUID

            DataManager.sharedManager.save(episode: episode)
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)

            let outputURL = URL(fileURLWithPath: streamingBufferPathForEpisode(episode), isDirectory: false)
            FileLog.shared.addMessage("DownloadManager export session: start exporting \(episode.uuid)")
            let exportCompleted = await MediaExporter.exportMediaItem(playbackItem, to: outputURL)
            if exportCompleted, let episode = dataManager.findBaseEpisode(uuid: episode.uuid) {
                var downloadStatus = DownloadStatus.downloadedForStreaming
                if episode.autoDownloadStatus == AutoDownloadStatus.notSpecified.rawValue || episode.autoDownloadStatus == AutoDownloadStatus.autoDownloaded.rawValue {
                    moveBufferedToCache(episode: episode)
                } else {
                    let fileSize = FileManager.default.fileSize(of: outputURL) ?? 0
                    DataManager.sharedManager.saveEpisode(downloadStatus: downloadStatus, sizeInBytes: fileSize, downloadTaskId: nil, episode: episode)
                    NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloaded, object: episode.uuid)
                }
            } else {
                DataManager.sharedManager.saveEpisode(downloadStatus: .notDownloaded, downloadError: nil, downloadTaskId: nil, episode: episode)
            }
            downloadingEpisodesCache.removeValue(forKey: episode.uuid)
        }
        #endif
        return playbackItem
    }

    private func markUnplayedAndUnarchiveIfRequired(episode: BaseEpisode, saveChanges: Bool) {
        var episodeModified = false

        if episode.played() {
            FileLog.shared.addMessage("Marking episode as unplayed because it's getting added to the download queue: \(episode.displayableTitle())")
            episode.playingStatus = PlayingStatus.notPlayed.rawValue
            episode.playingStatusModified = TimeFormatter.currentUTCTimeInMillis()
            episode.playedUpTo = 0
            episode.playedUpToModified = TimeFormatter.currentUTCTimeInMillis()

            episodeModified = true
        }
        if episode.archived, let episode = episode as? Episode {
            FileLog.shared.addMessage("Un-archiving episode because it's getting added to the download queue: \(episode.displayableTitle())")
            episode.archived = false
            episode.archivedModified = TimeFormatter.currentUTCTimeInMillis()
            episode.lastArchiveInteractionDate = Date()

            // if this podcast has an episode limit, flag this episode as being manually excluded from that limit
            if let parentPodcast = episode.parentPodcast(), parentPodcast.autoArchiveEpisodeLimitCount > 0 {
                episode.excludeFromEpisodeLimit = true
            }

            episodeModified = true
        }

        if episodeModified, saveChanges {
            dataManager.save(episode: episode)
        }
    }

    func performAddToQueue(episode: BaseEpisode, url: String, previousDownloadFailed: Bool, fireNotification: Bool, autoDownloadStatus: AutoDownloadStatus) async {

        var downloadUrl = URL(string: url)
        if downloadUrl == nil {
            // if the download URL is nil, try encoding the URL to see if that works
            if let encodedStr = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
                downloadUrl = URL(string: encodedStr)
            }
        }

        // make sure the URL is valid and has a supported scheme: only http and https are allowed
        guard let url = downloadUrl, let scheme = url.scheme, scheme.count > 0, scheme.caseInsensitiveCompare("http") == .orderedSame || scheme.caseInsensitiveCompare("https") == .orderedSame else {
            dataManager.saveEpisode(downloadStatus: .downloadFailed, downloadError: L10n.downloadErrorContactAuthor, downloadTaskId: nil, episode: episode)

            logDownload(episode, failure: .malformedHost)

            if fireNotification { NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid) }

            return
        }

        var request = URLRequest(url: url)
        request.addValue(ServerConstants.Values.appUserAgent, forHTTPHeaderField: ServerConstants.HttpHeaders.userAgent)
        request.timeoutInterval = 30.seconds

        let tempFilePath = tempPathForEpisode(episode)
        let mobileDataAllowed = autoDownloadStatus == .autoDownloaded ? Settings.autoDownloadMobileDataAllowed() : Settings.mobileDataAllowed()
        let useCellularSession = (mobileDataAllowed || (!NetworkUtils.shared.isConnectedToWifi() && autoDownloadStatus != .autoDownloaded)) // allow cellular downloads if not on WiFi and not auto downloaded, because it means the user said yes to a confirmation prompt

        #if os(watchOS)
            let sessionToUse = await WKApplication.shared().applicationState == .background ? cellularBackgroundSession : cellularForegroundSession
        #else
            let sessionToUse = useCellularSession ? cellularBackgroundSession : wifiOnlyBackgroundSession
        #endif

        if FeatureFlag.downloadFixes.enabled {
            if await shouldSkipExistingTask(for: episode, in: sessionToUse, matching: request) {
                FileLog.shared.addMessage("Download: skipped task for episode: \(episode.uuid)")
                return
            }
        }

        FileLog.shared.addMessage("Downloading episode \(episode.displayableTitle()), autoDownloadStatus: \(autoDownloadStatus), previousDownloadFailed: \(previousDownloadFailed)")
        resumeDownload(tempFilePath: tempFilePath, session: sessionToUse, request: request, previousDownloadFailed: previousDownloadFailed, taskId: episode.uuid, estimatedBytes: episode.sizeInBytes)

        if fireNotification { NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid) }
    }

    private func shouldSkipExistingTask(for episode: BaseEpisode, in session: URLSession, matching request: URLRequest) async -> Bool {
        if let task = await session.existingTask(for: episode) {
            if task.originalRequest?.url == request.url {
                if task.error == nil {
                    // As long as we don't have an error, we'll skip starting a new download, otherwise we'll need the new task anyway
                    // Before this change, we allowed any new download so we'd rather start out more restrictive
                    return true
                }
            } else {
                // If the request URLs don't match, we should cancel the old task since it is expected to be downloading old content
                task.cancel()
            }
        }
        return false
    }

    func removeFromQueue(episodeUuid: String, fireNotification: Bool, userInitiated: Bool) {
        guard let episode = dataManager.findBaseEpisode(uuid: episodeUuid) else { return }

        removeFromQueue(episode: episode, fireNotification: fireNotification, userInitiated: userInitiated)
    }

    // note, this method should only be called if you just grabbed the episode from the DB, if you're unsure how fresh your episode is, use the episodeUuid method
    func removeFromQueue(episode: BaseEpisode, fireNotification: Bool, userInitiated: Bool) {
        let uniquedDownloadId = episode.downloadTaskId
        cancelTaskId(uniquedDownloadId, episode: episode, session: wifiOnlyBackgroundSession)
        cancelTaskId(uniquedDownloadId, episode: episode, session: cellularBackgroundSession)
        #if os(watchOS)
            cancelTaskId(uniquedDownloadId, episode: episode, session: cellularForegroundSession)
        #endif

        removeEpisodeFromCache(episode)

        var saveRequired = false
        if uniquedDownloadId != nil {
            episode.downloadTaskId = nil
            saveRequired = true
        }

        if userInitiated {
            episode.autoDownloadStatus = AutoDownloadStatus.userCancelledDownload.rawValue
            saveRequired = true
        }
        if episode.queued() || episode.downloading() || episode.waitingForWifi() {
            episode.episodeStatus = DownloadStatus.notDownloaded.rawValue
            saveRequired = true
        }

        if saveRequired { dataManager.save(episode: episode) }

        if fireNotification { NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid) }
    }

    private func shouldAddDownload(_ episodeUuid: String, autoDownloadStatus: AutoDownloadStatus) -> Bool {
        guard let episode = dataManager.findBaseEpisode(uuid: episodeUuid) else { return false }

        if let taskId = episode.downloadTaskId, episode.autoDownloadStatus == AutoDownloadStatus.playerDownloadedForStreaming.rawValue, autoDownloadStatus != .playerDownloadedForStreaming {
            // if the player was downloading an episode for streaming purposes, and now the user (or the app via auto download) is downloading it, change the status
            episode.autoDownloadStatus = autoDownloadStatus.rawValue
            episode.episodeStatus = DownloadStatus.downloading.rawValue
            dataManager.save(episode: episode)
            downloadingEpisodesCache[taskId] = episode
            NotificationCenter.postOnMainThread(notification: Constants.Notifications.episodeDownloadStatusChanged, object: episode.uuid)
            return false
        }

        if episode.episodeStatus == DownloadStatus.notDownloaded.rawValue || episode.episodeStatus == DownloadStatus.downloadFailed.rawValue || !isEpisodeDownloading(episode) {
            dataManager.clearDownloadTaskId(episode: episode)
            episode.downloadTaskId = nil
        }

        return (episode.downloadTaskId == nil)
    }

    func isEpisodeDownloading(_ episode: BaseEpisode) -> Bool {
        return downloadingEpisodesCache.contains(where: { (_, downloadingEpisode) in
            return episode.uuid == downloadingEpisode.uuid
        })
    }

    func tempPathForEpisode(_ episode: BaseEpisode) -> String {
        let fileName = episode.uuid + episode.fileExtension()
        let path = (tempDownloadFolder as NSString).appendingPathComponent(fileName)

        return path
    }

    func pathForEpisode(_ episode: BaseEpisode) -> String {
        let fileName = episode.uuid + episode.fileExtension()
        let path = (podcastsDirectory as NSString).appendingPathComponent(fileName)

        return path
    }

    func pathForUrl(fileUrl: URL, uuid: String) -> String {
        let fileExtension = fileUrl.pathExtension.lowercased()
        let fileName = uuid + "." + fileExtension
        let path = (podcastsDirectory as NSString).appendingPathComponent(fileName)

        return path
    }

    func streamingBufferPathForEpisode(_ episode: BaseEpisode) -> String {
        let fileExtension = episode.fileExtension()
        let fileName = episode.uuid + fileExtension
        let path = (streamingBufferDirectory as NSString).appendingPathComponent(fileName)

        return path
    }

    func streamingBufferFolder() -> String {
        streamingBufferDirectory
    }

    private func cancelTaskId(_ taskId: String?, episode: BaseEpisode, session: URLSession) {
        guard let taskId = taskId else { return }

        session.getTasksWithCompletionHandler { [weak self] _, _, downloadTasks in
            if downloadTasks.count == 0 { return }

            for task in downloadTasks {
                if taskId == task.taskDescription {
                    self?.cancelTask(task, for: episode)

                    return
                }
            }
        }
    }

    private func cancelTask(_ task: URLSessionDownloadTask, for episode: BaseEpisode) {
        task.cancel { [weak self] data in
            if let data = data, data.count > 0, let tempFilePath = self?.tempPathForEpisode(episode) {
                do {
                    try data.write(to: URL(fileURLWithPath: tempFilePath), options: .atomic)
                } catch {
                    FileLog.shared.addMessage("Failed to save resume data \(error.localizedDescription)")
                }
            }
        }
    }

    func removeEpisodeFromCache(_ episode: BaseEpisode) {
        progressManager.removeProgressForEpisode(episode.uuid)

    }

    private func resumeDownload(tempFilePath: String, session: URLSession, request: URLRequest, previousDownloadFailed: Bool, taskId: String, estimatedBytes: Int64) {
        let fileManager = FileManager.default
        var downloadTask: URLSessionDownloadTask?
        do {
            if fileManager.fileExists(atPath: tempFilePath) {
                if previousDownloadFailed {
                    try fileManager.removeItem(atPath: tempFilePath)
                } else {
                    let resumeData = try Data(contentsOf: URL(fileURLWithPath: tempFilePath))
                    downloadTask = session.downloadTask(withResumeData: resumeData)
                }
            }
        } catch {
            // something went wrong, just start a new download
            downloadTask = nil
        }

        // either there is no resume data, or we got an exception trying to restore the resume data, or somehow the task has no request
        if downloadTask?.currentRequest == nil {
            do { try fileManager.removeItem(atPath: tempFilePath) } catch {}
            downloadTask = session.downloadTask(with: request)
            if estimatedBytes > 0 {
                downloadTask?.countOfBytesClientExpectsToReceive = estimatedBytes
            } else {
                // if there's no known size for this file, and we're on watchOS, specify 20MB's so the scheduler knows it's going to be a decent size download
                #if os(watchOS)
                    downloadTask?.countOfBytesClientExpectsToReceive = Int64(20.megabytes)
                #endif
            }
        }

        downloadTask?.taskDescription = taskId
        downloadTask?.resume()
    }

    func startAllQueued() {
        let queuedEpisodes = dataManager.findEpisodesWhere(customWhere: "episodeStatus == ?", arguments: [DownloadStatus.queued.rawValue])
        queuedEpisodes.forEach { episode in
            Task {
                addToQueue(episodeUuid: episode.uuid)
            }
        }
    }

    func cancelTasks(for episodes: [BaseEpisode]) async {
        let matchingTasks = await tasks(for: episodes)

        matchingTasks.forEach {
            $0.cancel()
        }
    }

    func tasks(for episodes: [BaseEpisode]) async -> [URLSessionTask] {
        let matchingTasks = await allTasks().filter { task in
            let identifier = task.taskDescription
            return episodes.contains { episode in
                episode.downloadTaskId == identifier || episode.uuid == identifier
            }
        }

        return matchingTasks
    }

    func allTasks() async -> [URLSessionTask] {
        return [await wifiOnlyBackgroundSession.allTasks,
         await cellularForegroundSession.allTasks,
         await cellularBackgroundSession.allTasks].flatMap { $0 }
    }
}
